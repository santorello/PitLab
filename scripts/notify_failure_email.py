#!/usr/bin/env python3
"""Send a GitHub Actions failure email through SMTP."""

from __future__ import annotations

import os
import smtplib
import ssl
import sys
from email.message import EmailMessage


RECIPIENT = "beppe.apps@gmail.com"


def getenv_required(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        print(f"Missing required environment variable: {name}", file=sys.stderr)
        sys.exit(2)
    return value


def github_run_url() -> str:
    server_url = os.getenv("GITHUB_SERVER_URL", "https://github.com").rstrip("/")
    repository = os.getenv("GITHUB_REPOSITORY", "unknown/repository")
    run_id = os.getenv("GITHUB_RUN_ID", "")
    if run_id:
        return f"{server_url}/{repository}/actions/runs/{run_id}"
    return f"{server_url}/{repository}/actions"


def build_message(sender: str) -> EmailMessage:
    repository = os.getenv("GITHUB_REPOSITORY", "unknown/repository")
    workflow = os.getenv("GITHUB_WORKFLOW", "unknown workflow")
    ref_name = os.getenv("GITHUB_REF_NAME", "unknown ref")
    run_url = github_run_url()

    message = EmailMessage()
    message["From"] = sender
    message["To"] = RECIPIENT
    message["Subject"] = f"[PitLab] Supabase keepalive failed on {ref_name}"
    message.set_content(
        "\n".join(
            [
                "Supabase keepalive GitHub Action failed.",
                "",
                f"Repository: {repository}",
                f"Workflow: {workflow}",
                f"Branch/ref: {ref_name}",
                f"Run: {run_url}",
                "",
                "Open the run URL to inspect the failing step logs.",
            ]
        )
    )
    return message


def main() -> int:
    smtp_host = getenv_required("SMTP_HOST")
    smtp_user = getenv_required("SMTP_USER")
    smtp_password = getenv_required("SMTP_PASSWORD")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_from = os.getenv("SMTP_FROM", smtp_user).strip() or smtp_user

    message = build_message(smtp_from)

    context = ssl.create_default_context()
    with smtplib.SMTP(smtp_host, smtp_port, timeout=30) as server:
        server.starttls(context=context)
        server.login(smtp_user, smtp_password)
        server.send_message(message)

    print(f"Failure notification sent to {RECIPIENT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
