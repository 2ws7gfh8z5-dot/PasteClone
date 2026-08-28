#[path = "../src/history.rs"]
mod history;
use history::{insert, Clip};

#[test]
fn duplicate_pinned_item_survives_and_moves_first() {
    let mut items = vec![
        Clip::new("other".into()),
        Clip {
            text: "same".into(),
            pinned: true,
        },
    ];
    insert(&mut items, "same".into(), 10);
    assert_eq!(items[0].text, "same");
    assert!(items[0].pinned);
    assert_eq!(items.len(), 2);
}
