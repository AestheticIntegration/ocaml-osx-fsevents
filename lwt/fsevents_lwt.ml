(*
 * Copyright (c) 2015 David Sheets <sheets@alum.mit.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

type event = {
  path  : string;
  flags : Fsevents.EventFlags.t;
  id    : Fsevents.EventId.t;
}

type t = {
  stream : event Lwt_stream.t;
  push : event option -> unit;
  event_stream : Fsevents.t;
}

let create ?since latency flags paths =
  let stream, push = Lwt_stream.create () in
  let import path flags id = Lwt_preemptive.run_in_main (fun () ->
    (try push (Some { path; flags; id; }) with Lwt_stream.Closed -> ());
    Lwt.return_unit
  ) in
  let event_stream = Fsevents.create ?since latency flags import paths in
  { stream; push; event_stream }

let get_latest_event_id { event_stream } =
  Fsevents.get_latest_event_id event_stream

let start { event_stream } = Fsevents.start event_stream

let schedule_with_run_loop { event_stream } =
  Fsevents.schedule_with_run_loop event_stream

let stream { stream } = stream

let event_stream { event_stream } = event_stream

let flush { event_stream } =
  Lwt_preemptive.detach Fsevents.flush_sync event_stream

let stop { event_stream } = Fsevents.stop event_stream

let invalidate { event_stream; push } =
  Fsevents.invalidate event_stream;
  push None

let release { event_stream } =
  Lwt.async Lwt.Infix.(fun () ->
    Lwt_unix.sleep 5.
    >>= fun () ->
    Fsevents.release event_stream;
    Lwt.return_unit
  )

