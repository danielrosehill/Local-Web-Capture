// Batch capture report template.
// Inputs expected via --input:
//   manifest = absolute path to report.agent.json (list of items + metadata)
//   capture_root = absolute path to the batch directory
//   title = batch title (default: "Batch Capture Report")
//
// Each article body is read from its file path in the manifest.

#let manifest_path = sys.inputs.at("manifest", default: none)
#let capture_root  = sys.inputs.at("capture_root", default: "")
#let doc_title     = sys.inputs.at("title", default: "Batch Capture Report")

#if manifest_path == none {
  panic("Missing --input manifest=<path-to-report.agent.json>")
}

#let data = json(manifest_path)

#set document(title: doc_title, author: "Local-Web-Capture")
#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.2cm),
  footer: context [
    #set align(center)
    #set text(size: 9pt, fill: luma(110))
    Page #counter(page).display("1") of #counter(page).final().first()
  ],
)
#set text(font: "Liberation Serif", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.68em)
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(above: 0em, below: 0.8em)[
    #set text(size: 18pt, weight: "bold")
    #it.body
  ]
}
#show heading.where(level: 2): it => {
  block(above: 1em, below: 0.5em)[
    #set text(size: 13pt, weight: "bold")
    #it.body
  ]
}
#show link: set text(fill: rgb("#0b5fb0"))

// ---- Cover ----
#align(center)[
  #v(4cm)
  #text(size: 24pt, weight: "bold")[#doc_title]
  #v(0.4cm)
  #text(size: 11pt, fill: luma(100))[
    Batch #raw(data.batch_id) · Generated #data.generated_at
  ]
  #v(0.6cm)
  #text(size: 10pt, fill: luma(110))[
    #data.counts.captured of #data.counts.submitted URLs captured ·
    #data.counts.failed failed ·
    #data.counts.thin thin
  ]
]

#pagebreak()

// ---- TOC ----
= Contents
#for (i, item) in data.items.enumerate() [
  #let n = str(i + 1).pad(left, 2, "0")
  *\[##n\]* #item.title #h(1fr) _#item.domain _ \
]

// ---- Items ----
#for (i, item) in data.items.enumerate() [
  #let n = str(i + 1).pad(left, 2, "0")
  = \[##n\] #item.title

  #block(fill: luma(245), inset: 10pt, radius: 3pt, width: 100%)[
    *Source URL:* #link(item.url)[#item.url] \
    *Captured:* #item.captured_at \
    *Domain:* #item.domain   \
    *Language:* #item.language   ·
    *Words:* #item.word_count   ·
    *Extractor:* #item.extractor (rung #item.rung)
  ]

  #v(0.5em)

  // Article body — read from file, strip YAML frontmatter, render markdown-ish text.
  // Typst's raw markdown support is limited; we read the file and render as plain
  // prose with paragraph breaks preserved. Headings become bold lines.
  #let body_path = capture_root + "/" + item.file
  #let raw_text = read(body_path)
  #let stripped = {
    let lines = raw_text.split("\n")
    let in_fm = false
    let hit_fm = false
    let out = ()
    for line in lines {
      if line == "---" {
        if not hit_fm { in_fm = true; hit_fm = true; continue }
        else if in_fm { in_fm = false; continue }
      }
      if not in_fm { out.push(line) }
    }
    out.join("\n")
  }

  #for para in stripped.split("\n\n") [
    #let p = para.trim()
    #if p.len() > 0 [
      #if p.starts-with("# ") [
        #text(weight: "bold", size: 13pt)[#p.slice(2)]
      ] else if p.starts-with("## ") [
        #text(weight: "bold", size: 12pt)[#p.slice(3)]
      ] else [
        #p
      ]
      #parbreak()
    ]
  ]
]
