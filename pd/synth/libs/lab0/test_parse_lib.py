# File:        test_parse_lib.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Tests for libs/lab0/parse_lib.py on every library in your track's track/libraries.yaml. Exact values come from the sky130_fd_sc_hd and gf180mcu 7-track tt files, when the track has them.
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from parse_lib import Library  # noqa: E402
from platforms import SPEC_PLATFORMS, cell_base, cell_name, lib_path  # noqa: E402


def _find(inv_base: str) -> str | None:
    """First library of this track whose inverter is named <inv_base>_<n>."""
    return next((p for p in SPEC_PLATFORMS if cell_base(p, "inv") == inv_base), None)


@pytest.fixture(scope="module")
def hd():
    p = _find("sky130_fd_sc_hd__inv")
    if p is None:
        pytest.skip("no sky130_fd_sc_hd library in this track")
    return Library.load(lib_path(p, "tt"))


@pytest.fixture(scope="module", params=SPEC_PLATFORMS)
def any_lib(request):
    return request.param, Library.load(lib_path(request.param, "tt"))


# --- any library ---
def test_units_and_corner_present(any_lib):
    _, lib = any_lib
    assert {"time", "capacitance", "leakage_power", "voltage"} <= set(lib.units)
    assert all(lib.units.values())
    assert set(lib.corner) == {"process", "voltage", "temperature"}
    assert lib.corner["voltage"] > 0


def test_inverter_pins(any_lib):
    p, lib = any_lib
    inv = lib.cell(cell_name(p, "inv", 1))
    assert len(inv.outputs()) == 1
    assert len(inv.inputs()) == 1
    assert inv.inputs()[0].capacitance > 0
    assert inv.area > 0


def test_lookup_on_every_grid_point(any_lib):
    p, lib = any_lib
    inv = lib.cell(cell_name(p, "inv", 1))
    t = inv.table(inv.outputs()[0].name, inv.inputs()[0].name, "cell_rise")
    slew_first = t.var_1.startswith("input_net_transition")
    for i, x1 in enumerate(t.index_1):
        for j, x2 in enumerate(t.index_2):
            slew, load = (x1, x2) if slew_first else (x2, x1)
            assert t.lookup(slew=slew, load=load) == pytest.approx(t.values[i][j], rel=1e-6)


def test_lookup_between_grid_points(any_lib):
    p, lib = any_lib
    inv = lib.cell(cell_name(p, "inv", 1))
    t = inv.table(inv.outputs()[0].name, inv.inputs()[0].name, "cell_rise")
    slews, loads = t.axes()
    s, l = (slews[0] + slews[1]) / 2, (loads[0] + loads[1]) / 2
    corners = [t.lookup(a, b) for a in slews[:2] for b in loads[:2]]
    assert min(corners) <= t.lookup(s, l) <= max(corners)
    assert np.isfinite(t.lookup(2 * slews[-1], 2 * loads[-1]))   # extrapolates


# --- sky130_fd_sc_hd, exact values ---
def test_units_and_corner(hd):
    assert hd.units["time"] == "1ns"
    assert hd.units["capacitance"].lower().endswith("pf")
    assert hd.corner["voltage"] == pytest.approx(1.8)
    assert hd.corner["temperature"] == pytest.approx(25)


def test_cell_basics(hd):
    inv = hd.cell("sky130_fd_sc_hd__inv_1")
    assert inv.area == pytest.approx(3.7536)
    assert inv.pin("A").capacitance == pytest.approx(0.002302)
    assert [p.name for p in inv.outputs()] == ["Y"]
    assert len(hd.cell_names()) == 428


def test_drive_strengths(hd):
    names = hd.drive_strengths("sky130_fd_sc_hd__inv")
    assert [n.rsplit("_", 1)[1] for n in names] == ["1", "2", "4", "6", "8", "12", "16"]


def test_lookup_on_grid_point(hd):
    # a table entry: slew 0.0230506 ns, load 0.0005 pF
    t = hd.cell("sky130_fd_sc_hd__inv_1").table("Y", "A", "cell_rise")
    assert t.lookup(slew=0.0230506, load=0.0005) == pytest.approx(0.02553, abs=1e-5)


def test_lookup_interpolates(hd):
    t = hd.cell("sky130_fd_sc_hd__inv_1").table("Y", "A", "cell_rise")
    v = t.lookup(slew=0.04, load=0.01)
    assert v == pytest.approx(0.087797, rel=1e-4)
    # more load or slower input -> more delay
    assert t.lookup(0.04, 0.02) > v
    assert t.lookup(0.08, 0.01) > v


# --- gf180mcu 7-track, exact values ---
def test_gf180_leakage_without_cell_leakage_power():
    # gf180 inv_1 at tt: leakage_power without a `when` condition
    p = _find("gf180mcu_fd_sc_mcu7t5v0__inv")
    if p is None:
        pytest.skip("no gf180mcu_fd_sc_mcu7t5v0 library in this track")
    gf = Library.load(lib_path(p, "tt"))
    inv = gf.cell("gf180mcu_fd_sc_mcu7t5v0__inv_1")
    assert inv.leakage == pytest.approx(7.6495e-05)
    assert inv.pin("I").capacitance == pytest.approx(0.004736)
