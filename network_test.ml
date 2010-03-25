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

open Format
open Factory.Network

type kind = Same | Mono | Poly

let worker = ref false
let kind = ref Poly
let test = ref ""
let local = ref false
let stop = ref false
let port = ref 51004

let () = Arg.parse
  ["-w", Arg.Set worker, "runs as a worker";
   "-mono", Arg.Unit (fun () -> kind := Mono), "use Network.Mono";
   "-same", Arg.Unit (fun () -> kind := Same), "use Network.Same";
   "-poly", Arg.Unit (fun () -> kind := Poly), "use Network.Poly";
   "-test", Arg.Set_string test, "<int> ";
   "-local", Arg.Set local, "use a worker on localhost";
   "-stop", Arg.Set stop, "stop the worker";
   "-port", Arg.Set_int port, "<int> set the port number";
  ]
  (fun _ -> ())
  "usage: "

let stop = !stop
let () = Factory.Control.set_default_port_number !port

let () = 
  if not !worker then begin
    if !local then 
      declare_workers ~n:2 "localhost"
    else
      declare_workers ~n:12 "moloch"
  end

let () = Factory.Control.set_debug true

open Mono

let double x = x+x
let double_string x = let x = int_of_string x in string_of_int (double x)

let () = match !kind with
  | Mono ->
      if !worker then begin
	printf "I'm a mono worker...@.";
	Mono.Worker.compute double_string ()
      end else begin
	let s = ref 0 in
	Mono.Master.compute
	  ~master:(fun _ r -> s := !s + int_of_string r; []) 
	  (List.map (fun x -> x,()) ["1";"2";"3"]);
	printf "%d@." !s;
	assert (!s = 12)
      end
  | Poly -> 
      if !worker then begin
	printf "I'm a poly worker...@.";
	match !test with
	  | "" ->
	      Poly.Worker.compute double ~stop ()
	  | "map" ->
	      Poly.Worker.map ~f:double ~stop ()
	  | "map_local_fold" ->
	      Poly.Worker.map_local_fold ~map:double ~stop ()
	  | "map_remote_fold" ->
	      Poly.Worker.map_remote_fold ~map:double ~fold:(+) ~stop ()
	  | "map_fold_ac" ->
	      Poly.Worker.map_fold_ac ~map:double ~fold:(+) ~stop ()
	  | "map_fold_a" ->
	      Poly.Worker.map_fold_a ~map:double ~fold:(+) ~stop ()
	  | _ ->
	      assert false (*TODO*)
      end else begin
	match !test with
	  | "" ->
	      let s = ref 0 in
	      Poly.Master.compute
		~master:(fun _ r -> s := !s + r; [])
		(List.map (fun x -> x,()) [1;2;3]);
	      printf "%d@." !s;
	      assert (!s = 12)
	  | "map" ->
	      assert (Poly.Master.map [1;2;3] = [2;4;6])
	  | "map_local_fold" ->
	      assert (Poly.Master.map_local_fold ~fold:(+) 0 [1;2;3] = 12)
	  | "map_remote_fold" ->
	      assert (Poly.Master.map_remote_fold 0 [1;2;3] = 12)
	  | "map_fold_ac" ->
	      assert (Poly.Master.map_fold_ac 0 [1;2;3] = 12)
	  | "map_fold_a" ->
	      assert (Poly.Master.map_fold_a 0 [1;2;3] = 12)
	  | _ ->
	      assert false (*TODO*)
      end
  | Same -> 
      if !worker then begin
	printf "I'm a same worker...@.";
	Same.Worker.compute ()
      end else begin
	match !test with
	  | "" ->
	      let s = ref 0 in
	      Same.compute
		~worker:double
		~master:(fun _ r -> s := !s + r; [])
		(List.map (fun x -> x,()) [1;2;3]);
	      printf "%d@." !s;
	      assert (!s = 12)
	  | "map" ->
	      assert (Same.map ~f:double [1;2;3] = [2;4;6])
	  | "map_local_fold" ->
	      assert (Same.map_local_fold ~map:double ~fold:(+) 0 [1;2;3] = 12)
	  | "map_remote_fold" ->
	      assert (Same.map_remote_fold ~map:double ~fold:(+) 0 [1;2;3] = 12)
	  | "map_fold_ac" ->
	      assert (Same.map_fold_ac ~map:double ~fold:(+) 0 [1;2;3] = 12)
	  | "map_fold_a" ->
	      assert (Same.map_fold_a ~map:double ~fold:(+) 0 [1;2;3] = 12)
	  | _ ->
	      assert false (*TODO*)
      end



