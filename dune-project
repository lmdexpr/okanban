(lang dune 3.11)

(name okanban)

(generate_opam_files true)

(source
 (github lmdexpr/okanban))

(authors "Yuki Tajiri")

(maintainers "Yuki Tajiri")

(license MIT)

(package
 (name okanban)
 (synopsis "Simple Kanban app written in OCaml")
 (description "A simple Kanban application with webhook reminder functionality")
 (depends
  (ocaml (>= 5.3.0))
  (dune (>= 3.11))
  dream
  yojson
  ppx_deriving_yojson
  ppx_fields_conv
  (odoc :with-doc)))
