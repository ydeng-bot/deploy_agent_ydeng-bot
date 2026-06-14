# Attendance Tracker — Project Factory

A Bash automation project that bootstraps a complete Student Attendance Tracker workspace from a single command.

The script demonstrates:

* Automated project scaffolding
* Configuration management using `sed`
* Environment validation
* Process management using signal traps
* Error handling and cleanup
* Reproducible project setup

---

## Repository Structure

```text
deploy_agent_ydeng-bot/
├── setup_project.sh
└── README.md
```

When executed, the script generates:

```text
attendance_tracker_<identifier>/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
    └── reports.log
```

---

## Features

### 1. Directory Automation

The script automatically:

* Creates the complete attendance tracker workspace
* Generates all required directories and files
* Prevents accidental overwriting of existing projects
* Handles directory creation errors gracefully

### 2. Configuration Management

The script prompts the user to configure attendance thresholds.

Values are validated before being written to `config.json`.

Validation rules:

* Must be numeric
* Must be between 1 and 99
* Empty values are rejected
* Invalid values trigger re-prompting

Configuration updates are performed using `sed`.

### 3. Environment Validation

A health check runs automatically after setup.

The script verifies:

```bash
python3 --version
```

It also confirms that:

* attendance_checker.py exists
* Helpers/assets.csv exists
* Helpers/config.json exists
* reports/reports.log exists

Any missing file is reported immediately.

### 4. Process Management

The script implements signal handling using:

```bash
trap cleanup SIGINT SIGTERM
```

If the user interrupts execution with Ctrl+C:

1. The partially created workspace is archived
2. The archive is saved as a `.tar.gz` file
3. The incomplete directory is deleted
4. The script exits safely with code `130`

This prevents workspace clutter and data loss.

---

## Requirements

| Requirement | Purpose                     |
| ----------- | --------------------------- |
| Bash 4.0+   | Execute bootstrap script    |
| python3     | Run attendance application  |
| sed         | Update configuration values |
| tar         | Archive incomplete builds   |

---

## Installation

### Clone Repository

```bash
git clone https://github.com/ydeng-bot/deploy_agent_ydeng-bot.git

cd deploy_agent_ydeng-bot
```

### Make Script Executable

```bash
chmod +x setup_project.sh
```

---

## Running the Script

### Interactive Mode

```bash
./setup_project.sh
```

The script will prompt for a project identifier.

Example:

```text
Enter project identifier:
cohort_A
```

### Inline Argument Mode

```bash
./setup_project.sh cohort_A
```

---

## Generated Workspace

Example:

```text
attendance_tracker_cohort_A/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
    └── reports.log
```

---

## Running the Attendance Application

```bash
cd attendance_tracker_cohort_A

python3 attendance_checker.py
```

---

## Testing Environment Validation

To test the health check:

```bash
python3 --version
```

Expected result:

```text
Python 3.x.x
```

The script performs this check automatically.

---

## Testing Configuration Validation

Examples of invalid input:

```text
abc
```

```text
90.5
```

```text
-5
```

```text
100
```

The script rejects these values and asks again until a valid integer is entered.

---

## Testing Signal Trap & Archive Recovery

### Step 1

Run the script:

```bash
./setup_project.sh
```

### Step 2

While the script is running, press:

```text
Ctrl + C
```

### Expected Behaviour

```text
[WARNING] interruption caught! Bundling workspace data...

[SUCCESS] State successfully archived ->
attendance_tracker_cohort_A_archive.tar.gz

[SUCCESS] Cleaned up partial build directory:
attendance_tracker_cohort_A

process killed early.
```

### Verify Archive

```bash
tar -tzf attendance_tracker_cohort_A_archive.tar.gz
```

This displays the archived contents.

---

## Error Handling

| Scenario                   | Behaviour                             |
| -------------------------- | ------------------------------------- |
| Empty project identifier   | Script exits with error               |
| Existing project directory | User is prompted before overwrite     |
| Invalid threshold value    | User is re-prompted                   |
| Missing python3            | Warning is displayed                  |
| Ctrl+C interruption        | Archive created and directory removed |
| Missing generated file     | Health check reports error            |

---

## Demonstration Video

The accompanying video demonstrates:

* Repository structure
* Script execution
* Directory creation
* Configuration updates using `sed`
* Environment validation
* Signal trap testing with Ctrl+C
* Archive generation
* Cleanup of incomplete builds

