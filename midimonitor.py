#!/usr/bin/env python3
"""
midimonitor.py
Created by Kalu Obasi

A very simple MIDI monitor using mido.

- Lists available MIDI input ports
- Opens the first available input port
- Prints the port name
- Prints all incoming messages (notes, pitch bend, CC, etc.)
"""

import sys
import mido


def choose_input_port() -> str:
    """Return the name of the MIDI input port to use (first one found)."""
    input_names = mido.get_input_names()

    if not input_names:
        print("No MIDI input devices found.")
        sys.exit(1)

    print("Available MIDI input ports:")
    for i, name in enumerate(input_names):
        print(f"  [{i}] {name}")

    # For now, just pick the first one
    port_name = input_names[0]
    print(f"\nConnecting to: {port_name!r}")
    return port_name


def main():
    port_name = choose_input_port()

    # Open the selected input port
    try:
        with mido.open_input(port_name) as inport:
            print("\nListening for MIDI messages... (Ctrl+C to quit)\n")
            # This will print *all* incoming messages, including:
            # - note_on / note_off
            # - control_change (knobs, sliders, etc.)
            # - pitchwheel (pitch bend)
            # - program_change
            # - channel_pressure, aftertouch, etc.
            for msg in inport:
                print(msg)
    except KeyboardInterrupt:
        print("\nStopping MIDI monitor.")
    except Exception as e:
        print(f"Error while reading from MIDI port: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
