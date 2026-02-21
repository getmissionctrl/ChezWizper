use anyhow::{Context, Result};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use tracing::{error, info};
use which::which;

pub struct WhisperTranscriber {
    command_path: PathBuf,
    model_path: Option<String>,
    language: String,
}

impl WhisperTranscriber {
    pub fn new(custom_path: Option<String>) -> Result<Self> {
        let command_path = if let Some(path) = custom_path {
            let custom_path = PathBuf::from(path);
            if custom_path.exists() {
                info!("Using custom moonshine-cli path: {:?}", custom_path);
                custom_path
            } else {
                return Err(anyhow::anyhow!(
                    "Custom moonshine-cli path does not exist: {:?}",
                    custom_path
                ));
            }
        } else {
            which("moonshine-cli")
                .context("moonshine-cli not found. Please install moonshine-cli")?
        };

        info!("Found moonshine-cli at: {:?}", command_path);

        Ok(Self {
            command_path,
            model_path: None,
            language: "en".to_string(),
        })
    }

    pub fn with_model_path(mut self, model_path: Option<String>) -> Self {
        self.model_path = model_path;
        self
    }

    pub fn with_language(mut self, language: String) -> Self {
        self.language = language;
        self
    }

    pub async fn transcribe(&self, audio_path: &PathBuf) -> Result<String> {
        info!("Transcribing audio file: {:?}", audio_path);

        let model_arg = if let Some(model_path) = &self.model_path {
            info!("Using custom model path: {}", model_path);
            model_path.clone()
        } else if let Ok(env_path) = std::env::var("MOONSHINE_MODEL_DIR") {
            env_path
        } else {
            return Err(anyhow::anyhow!(
                "No model path set. Set MOONSHINE_MODEL_DIR or provide model_path in config"
            ));
        };

        let mut cmd = Command::new(&self.command_path);
        cmd.arg("-f")
            .arg(audio_path)
            .arg("-m")
            .arg(&model_arg)
            .arg("-l")
            .arg(&self.language)
            .arg("-nt") // No timestamps
            .arg("-np") // No progress
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .stdin(Stdio::null());

        let output = cmd
            .output()
            .context("Failed to execute moonshine-cli command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            error!("moonshine-cli failed: {}", stderr);
            return Err(anyhow::anyhow!("Moonshine transcription failed: {}", stderr));
        }

        let transcription = String::from_utf8_lossy(&output.stdout);
        let transcription = transcription.trim().to_string();

        info!("Transcription complete: {} chars", transcription.len());

        Ok(transcription)
    }
}
