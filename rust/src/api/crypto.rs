use aes::cipher::{Block, BlockCipherDecrypt, BlockCipherEncrypt, KeyInit};
use aes::Aes128;

/// AES-128 key used by the motorcycle protocol (16 bytes).
const AES_KEY: &str = "3A0EB8655C01281FF4D95DF1CD123456";

/// Encrypt data using AES-128 ECB without padding.
///
/// The input length must be a multiple of 16 bytes.
fn encrypt_ecb(data: &[u8], key: &[u8]) -> Result<Vec<u8>, String> {
    if key.len() != 16 {
        return Err(format!(
            "AES-128 key must be 16 bytes, got {} bytes",
            key.len()
        ));
    }

    if data.len() % 16 != 0 {
        return Err(format!(
            "NoPadding requires a data length that is a multiple of 16 bytes, got {} bytes",
            data.len()
        ));
    }

    let cipher =
        Aes128::new_from_slice(key).map_err(|e| format!("Failed to initialize AES: {e}"))?;

    let mut output = data.to_vec();

    for chunk in output.chunks_exact_mut(16) {
        let block =
            Block::<Aes128>::try_from(&*chunk).map_err(|e| format!("Invalid AES block: {e}"))?;

        let mut block = block;
        cipher.encrypt_block(&mut block);
        chunk.copy_from_slice(&block);
    }

    Ok(output)
}

/// Decrypt data using AES-128 ECB without padding.
///
/// The ciphertext length must be a multiple of 16 bytes.
fn decrypt_ecb(data: &[u8], key: &[u8]) -> Result<Vec<u8>, String> {
    if key.len() != 16 {
        return Err(format!(
            "AES-128 key must be 16 bytes, got {} bytes",
            key.len()
        ));
    }

    if data.len() % 16 != 0 {
        return Err(format!(
            "Ciphertext length must be a multiple of 16 bytes, got {} bytes",
            data.len()
        ));
    }

    let cipher =
        Aes128::new_from_slice(key).map_err(|e| format!("Failed to initialize AES: {e}"))?;

    let mut output = data.to_vec();

    for chunk in output.chunks_exact_mut(16) {
        let block =
            Block::<Aes128>::try_from(&*chunk).map_err(|e| format!("Invalid AES block: {e}"))?;

        let mut block = block;
        cipher.decrypt_block(&mut block);
        chunk.copy_from_slice(&block);
    }

    Ok(output)
}

/// Encrypt a motorcycle command.
///
/// Accepts a hexadecimal plaintext string, such as
/// "00112233445566778899AABBCCDDEEFF".
///
/// Returns the ciphertext as an uppercase hexadecimal string.
#[flutter_rust_bridge::frb(sync)]
pub fn encrypt_command_hex(command_hex: String) -> Result<String, String> {
    let data =
        hex::decode(command_hex.trim()).map_err(|e| format!("Invalid hexadecimal command: {e}"))?;

    let key = hex::decode(AES_KEY).map_err(|e| format!("Invalid AES key format: {e}"))?;

    let encrypted = encrypt_ecb(&data, &key)?;

    Ok(hex::encode_upper(encrypted))
}

/// Decrypt a received motorcycle packet.
///
/// Accepts a hexadecimal ciphertext string and returns
/// the plaintext as an uppercase hexadecimal string.
#[flutter_rust_bridge::frb(sync)]
pub fn decrypt_packet_hex(cipher_hex: String) -> Result<String, String> {
    let data = hex::decode(cipher_hex.trim())
        .map_err(|e| format!("Invalid hexadecimal ciphertext: {e}"))?;

    let key = hex::decode(AES_KEY).map_err(|e| format!("Invalid AES key format: {e}"))?;

    let decrypted = decrypt_ecb(&data, &key)?;

    Ok(hex::encode_upper(decrypted))
}
