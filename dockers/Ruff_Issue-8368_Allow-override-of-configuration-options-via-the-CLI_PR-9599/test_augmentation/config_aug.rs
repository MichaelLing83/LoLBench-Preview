#![cfg(not(target_family = "wasm"))]

use std::fs;
use std::process::Command;
use std::str;

use anyhow::Result;
use insta_cmd::get_cargo_bin;
use tempfile::TempDir;

const BIN_NAME: &str = "ruff";

#[test]
fn isolated_inline_overrides_still_apply() -> Result<()> {
    let tempdir = TempDir::new()?;
    let long_file = tempdir.path().join("long.py");
    fs::write(
        &long_file,
        "value = \"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz\"\n",
    )?;

    let output = Command::new(get_cargo_bin(BIN_NAME))
        .args([
            "check",
            "--isolated",
            "--no-cache",
            "--output-format",
            "concise",
            "--config",
            "lint.select = [\"E501\"]",
            "--config",
            "line-length = 40",
        ])
        .arg(&long_file)
        .output()?;

    assert!(!output.status.success());
    let stdout = str::from_utf8(&output.stdout)?;
    assert!(stdout.contains("E501 Line too long"), "{stdout}");
    assert!(stdout.contains("(62 > 40)"), "{stdout}");
    Ok(())
}

#[test]
fn nested_pyproject_add_noqa_uses_cli_excludes() -> Result<()> {
    let tempdir = TempDir::new()?;
    let package = tempdir.path().join("pkg");
    fs::create_dir(&package)?;
    fs::write(package.join("pyproject.toml"), "[tool.ruff]\n")?;
    let generated = package.join("generated.py");
    fs::write(&generated, "import os\n")?;

    let output = Command::new(get_cargo_bin(BIN_NAME))
        .args([
            "check",
            "--add-noqa",
            "--no-cache",
            "--config",
            "exclude = [\"generated.py\"]",
        ])
        .arg(tempdir.path())
        .output()?;

    assert!(output.status.success());
    assert_eq!(fs::read_to_string(&generated)?, "import os\n");
    let stderr = str::from_utf8(&output.stderr)?;
    assert!(!stderr.contains("Added 1 noqa directive"), "{stderr}");
    Ok(())
}

#[test]
fn default_check_still_reports_unused_import() -> Result<()> {
    let tempdir = TempDir::new()?;
    let source = tempdir.path().join("unused_import.py");
    fs::write(&source, "import os\n")?;

    let output = Command::new(get_cargo_bin(BIN_NAME))
        .args(["check", "--no-cache", "--output-format", "concise"])
        .arg(&source)
        .output()?;

    assert!(!output.status.success());
    let stdout = str::from_utf8(&output.stdout)?;
    assert!(stdout.contains("F401"), "{stdout}");
    assert_eq!(fs::read_to_string(&source)?, "import os\n");
    Ok(())
}
