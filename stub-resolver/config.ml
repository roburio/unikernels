(* (c) 2017, 2018 Hannes Mehnert, all rights reserved *)

open Mirage

let address =
  let network = Ipaddr.V4.Prefix.of_address_string_exn "10.0.42.6/24"
  and gateway = Some (Ipaddr.V4.of_string_exn "10.0.42.1")
  in
  { network ; gateway }

let net =
  if_impl Key.is_unix
    (socket_stackv4 [Ipaddr.V4.any])
    (static_ipv4_stack ~config:address ~arp:farp default_network)

let dns_handler =
  let packages = [
    package "logs" ;
    package ~sublibs:[ "server" ; "mirage.resolver" ; "crypto" ]
      ~pin:"git+https://github.com/roburio/udns.git" "udns" ;
    package "randomconv" ;
    package "lru" ;
    package "rresult" ;
    package "duration" ;
  ] in
  foreign
    ~deps:[abstract nocrypto ; abstract app_info]
    ~packages
    "Unikernel.Main" (random @-> pclock @-> mclock @-> time @-> stackv4 @-> job)

let () =
  register "stub-resolver" [dns_handler $ default_random $ default_posix_clock $ default_monotonic_clock $ default_time $ net ]
