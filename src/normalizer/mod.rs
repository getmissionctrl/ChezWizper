use anyhow::Result;
use regex::Regex;
use tracing::debug;

/// Trait for normalizing transcription output
pub trait TranscriptionNormalizer: Send + Sync {
    /// Normalize the raw transcription output
    fn normalize(&self, raw_output: &str) -> String;

    /// Get the name of this normalizer for logging
    fn name(&self) -> &'static str;
}

/// Normalizer for whisper.cpp-compatible output format (used by moonshine-cli)
pub struct WhisperCppNormalizer {
    timestamp_regex: Regex,
}

impl WhisperCppNormalizer {
    pub fn new() -> Result<Self> {
        // Matches timestamps like [00:00:00.000 --> 00:00:03.280] or [00:00:00:000 --> 00:00:03:280]
        let timestamp_regex =
            Regex::new(r"\[\d{2}:\d{2}:\d{2}[:.]\d{3}\s*-->\s*\d{2}:\d{2}:\d{2}[:.]\d{3}\]\s*")?;

        Ok(Self { timestamp_regex })
    }
}

impl TranscriptionNormalizer for WhisperCppNormalizer {
    fn normalize(&self, raw_output: &str) -> String {
        debug!("Normalizing transcription output");

        let mut cleaned = String::new();

        for line in raw_output.lines() {
            // Remove timestamps from the beginning of lines
            let line_cleaned = self.timestamp_regex.replace_all(line, "");
            let line_trimmed = line_cleaned.trim();

            // Skip empty lines
            if !line_trimmed.is_empty() {
                if !cleaned.is_empty() {
                    cleaned.push(' ');
                }
                cleaned.push_str(line_trimmed);
            }
        }

        let result = cleaned.trim().to_string();
        debug!(
            "Normalized {} chars to {} chars",
            raw_output.len(),
            result.len()
        );

        result
    }

    fn name(&self) -> &'static str {
        "WhisperCppNormalizer"
    }
}

pub struct Normalizer {
    inner: WhisperCppNormalizer,
}

impl Normalizer {
    pub fn create() -> Result<Self> {
        Ok(Self {
            inner: WhisperCppNormalizer::new()?,
        })
    }

    pub fn run(&self, raw_output: &str) -> String {
        debug!("Running {}", self.inner.name());
        self.inner.normalize(raw_output)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_whisper_cpp_normalizer() {
        let normalizer = WhisperCppNormalizer::new().unwrap();

        let input = "[00:00:00.000 --> 00:00:03.280] This is me talking\n[00:00:03.280 --> 00:00:05.000] And more text";
        let expected = "This is me talking And more text";

        assert_eq!(normalizer.normalize(input), expected);
    }

    #[test]
    fn test_whisper_cpp_normalizer_with_colons() {
        let normalizer = WhisperCppNormalizer::new().unwrap();

        let input = "[00:00:00:000 --> 00:00:03:280] This is me talking";
        let expected = "This is me talking";

        assert_eq!(normalizer.normalize(input), expected);
    }
}
