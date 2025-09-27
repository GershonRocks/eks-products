# Start production environment
make -f Makefile.production prod-up

# Check status
make -f Makefile.production prod-status

# View logs
make -f Makefile.production prod-logs

# Create backup
make -f Makefile.production prod-backup

# Security scan
make -f Makefile.production prod-security-scan
