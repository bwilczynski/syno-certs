# Synology Let's Encrypt Certificate Automation

This project provides scripts to automate the issuance and renewal of Let's Encrypt SSL certificates on Synology NAS using the [lego](https://github.com/go-acme/lego) client and DNS-01 challenge (with AWS Route53 by default).  
It is designed for DSM 7+ and uses Synology's API to update the system certificate automatically.

---

## Features

- **Automatic certificate issuance and renewal** for single and wildcard domains.
- **DNS-01 challenge** support (default: AWS Route53, but can be adapted for other providers).
- **Automatic import** of new certificates into Synology using the official API.
- **Easy configuration** via `.env` file.
- **Install script** for quick setup.

---

## Installation

1. **Run the install script as root:**

   ```bash
   wget -qO - https://raw.githubusercontent.com/bwilczynski/syno-certs/main/install.sh | sudo bash
   ```

   The script will:

   - Prompt you for your domain(s), email, and AWS credentials.
   - Create the configuration file at `/etc/local/syno-certs/default.env`.
   - Download and install the latest `lego` binary to `/usr/local/bin/lego`.

2. **Edit configuration if needed:**

   All settings are stored in `/etc/local/syno-certs/default.env`.  
   You can edit this file to change domains, email, or AWS credentials at any time.

---

## Usage

To manually issue or renew certificates and update Synology, run as root:

```bash
/usr/local/bin/update-syno-cert.sh
```

> The script will only renew and import certificates if they are close to expiry or missing.

---

## Automation

To automate certificate renewal:

1. **Open DSM Control Panel > Task Scheduler.**
2. **Create > Scheduled Task > User-defined script.**
3. **Set user to `root`.**
4. **Script example:**
   ```
   /usr/local/bin/update-syno-cert.sh
   ```
5. **Set the schedule** (e.g. weekly).

---

## Configuration

- Main config: `/etc/local/syno-certs/default.env`
- Example `.env` file:

  ```bash
  DOMAIN="example.com,*.example.com"
  EMAIL="admin@example.com"
  DNS_PROVIDER="route53"

  AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
  AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
  AWS_REGION="eu-west-1"
  ```

---

## Requirements

- Synology DSM 7+
- Root access for installation and scheduled tasks
- AWS Route53 credentials (or adapt for another DNS provider)
- Internet access for Let's Encrypt and AWS API

---

## Security

- The `.env` file contains sensitive credentials.  
  Make sure `/etc/local/syno-certs/default.env` is readable only by root.

---

## License

MIT

---

## Credits

- [lego](https://github.com/go-acme/lego)
