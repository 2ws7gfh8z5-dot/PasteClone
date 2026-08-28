use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct Clip {
    pub text: String,
    pub pinned: bool,
}

impl Clip {
    pub fn new(text: String) -> Self {
        Self {
            text,
            pinned: false,
        }
    }
    pub fn hash(&self) -> String {
        format!("{:x}", Sha256::digest(self.text.as_bytes()))
    }
}

pub fn insert(items: &mut Vec<Clip>, text: String, limit: usize) {
    if text.trim().is_empty() {
        return;
    }
    let incoming = Clip::new(text);
    let hash = incoming.hash();
    let retained = items
        .iter()
        .find(|item| item.hash() == hash && item.pinned)
        .cloned();
    items.retain(|item| item.hash() != hash);
    items.insert(0, retained.unwrap_or(incoming));
    trim(items, limit);
}

pub fn trim(items: &mut Vec<Clip>, limit: usize) {
    let mut kept = 0;
    items.retain(|item| {
        if item.pinned || kept < limit {
            if !item.pinned {
                kept += 1;
            }
            true
        } else {
            false
        }
    });
}
