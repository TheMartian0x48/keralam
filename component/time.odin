package component

import clock "core:time"
import "core:time/datetime"
import k "kashmir:."

// ---------- constants ----------

TIME_EXTRAS_MAX :: 4 // data-controller, format value, utc value, plus headroom

// What the element shows. Iso is never rewritten; the others are reformatted in the reader's
// locale by the keralam-time controller, and the server's text is the English fallback.
Time_Format :: enum u8 {
	date, // 17 May 2024
	date_time, // 17 May 2024, 14:30 UTC
	time, // 14:30 UTC
	iso, // 2024-05-17T14:30:00Z, as is
}

@(private)
time_format_names := [Time_Format]string {
	.date      = "date",
	.date_time = "date-time",
	.time      = "time",
	.iso       = "iso",
}

@(private)
time_month_names := [?]string {
	"Jan",
	"Feb",
	"Mar",
	"Apr",
	"May",
	"Jun",
	"Jul",
	"Aug",
	"Sep",
	"Oct",
	"Nov",
	"Dec",
}

// ---------- props ----------

// A moment in time, as a semantic <time> element.
//
//   time(doc, {value = clock.now(), format = .date_time})
//
// datetime always holds the instant in UTC, and never changes. Without script the text is an
// English rendering in UTC, which is correct and says so. With keralam.js the text is
// rewritten in the reader's locale and timezone (or UTC, with utc = true), and a Date shows
// the full date, time and zone as its hover title. Two readers of one page can therefore see
// different text; use Iso or utc to fix it. A <time> added to the page later is formatted too.
//
// value is an instant (core:time), so there is no timezone to guess. Relative text such as
// "2 hours ago" is not supported yet (see task.md).
//
// Asserts: value is within the years core:time can express (about 1678 to 2262).
Time_Props :: struct {
	using base: k.Base, // id, class (appended after "time"), style, attributes
	value:      clock.Time,
	format:     Time_Format,
	utc:        bool, // show UTC, not the reader's timezone
}

// ---------- procs ----------

// Composition order: time [class]
time :: proc(doc: ^k.Doc, props: Time_Props) -> k.Node_Id {
	moment, ok := clock.time_to_datetime(props.value)
	assert(ok, "time value is outside the years core:time can express")

	// k.time copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + TIME_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"time attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	if props.format != .iso {
		attributes[attributes_count] = k.attribute("data-controller", "keralam-time")
		attributes[attributes_count + 1] = k.attribute(
			"data-keralam-time-format-value",
			time_format_names[props.format],
		)
		attributes_count += 2
		if props.utc {
			attributes[attributes_count] = k.attribute("data-keralam-time-utc-value", "true")
			attributes_count += 1
		}
	}

	base := props.base
	base.class = props.class != "" ? k.doc_format(doc, "time %s", props.class) : "time"
	base.attributes = attributes[:attributes_count]
	return k.time(
		doc,
		{base = base, datetime = time_iso(doc, moment)},
		k.text(doc, time_fallback(doc, moment, props.format)),
	)
}

@(private)
time_iso :: proc(doc: ^k.Doc, moment: datetime.DateTime) -> string {
	return k.doc_format(
		doc,
		"%04d-%02d-%02dT%02d:%02d:%02dZ",
		moment.year,
		moment.month,
		moment.day,
		moment.hour,
		moment.minute,
		moment.second,
	)
}

@(private)
time_fallback :: proc(doc: ^k.Doc, moment: datetime.DateTime, format: Time_Format) -> string {
	switch format {
	case .date:
		return k.doc_format(
			doc,
			"%d %s %d",
			moment.day,
			time_month_names[moment.month - 1],
			moment.year,
		)
	case .date_time:
		return k.doc_format(
			doc,
			"%d %s %d, %02d:%02d UTC",
			moment.day,
			time_month_names[moment.month - 1],
			moment.year,
			moment.hour,
			moment.minute,
		)
	case .time:
		return k.doc_format(doc, "%02d:%02d UTC", moment.hour, moment.minute)
	case .iso:
		return time_iso(doc, moment)
	}
	unreachable()
}
