(**************************************************************************)
(*                                                                        *)
(*  Factory: a distributed computing library for Ocaml                    *)
(*  Copyright (C) 2010 Jean-Christophe Filliatre and Kalyan Krishnamani   *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

let debug = ref false

let set_debug b = debug := b

let buf = Buffer.create 1024
let fmt = Format.formatter_of_buffer buf

let default_port_number = ref 51002

let set_default_port_number p = default_port_number := p

let pong_timeout = ref 5.

let set_pong_timeout t = pong_timeout := t

let ping_interval = ref 10.

let set_ping_interval t = ping_interval := t

let dprintf s =
  Format.kfprintf 
    (fun _ -> 
       if !debug then begin 
	 Format.eprintf "%s" (Buffer.contents buf); 
	 Buffer.reset buf;
	 flush stderr 
       end)
    fmt s


