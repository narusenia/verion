#!/usr/bin/env python3
"""Writes the M7 evaluation scenes, where most of the light arrives indirectly and paths are long (REQ-ACC-004):

  indoor           two rooms joined by a doorway; the only light is a ceiling panel in the far room, the camera is in
                   the near room, so the picture is lit by light bounced through the door. Six diffuse colours and a
                   rough metal sphere.
  cornell_diffuse  the Cornell Box with two white boxes instead of the spheres: diffuse only, albedo up to 0.75.

The geometry is embedded. Usage: gen_indirect_scene.py indoor|cornell_diffuse OUT_FILE"""
import base64, json, math, struct, sys

from gen_cornell_scene import quad
from gen_showcase_scene import sphere


def flat(name, rgb, extra=None, emission=0.0):
    # ior 1 leaves the diffuse materials without a specular coat, as in cornell_box.
    m = {"name": name, "pbrMetallicRoughness": {"baseColorFactor": rgb + [1], "metallicFactor": 0, "roughnessFactor": 1},
         "extensions": {"KHR_materials_ior": {"ior": 1.0}, **(extra or {})}}
    if emission:
        m["emissiveFactor"] = [1, 1, 1]
        m["extensions"]["KHR_materials_emissive_strength"] = {"emissiveStrength": emission}
    return m


MATERIALS = {
    "white": flat("white", [0.75, 0.75, 0.75]),
    "wood": flat("wood", [0.5, 0.33, 0.18]),
    "red": flat("red", [0.75, 0.15, 0.15]),
    "green": flat("green", [0.15, 0.6, 0.15]),
    "blue": flat("blue", [0.15, 0.25, 0.7]),
    "yellow": flat("yellow", [0.8, 0.65, 0.15]),
    "light": flat("light", [0, 0, 0], emission=20),
    "metal": {"name": "metal", "pbrMetallicRoughness": {"baseColorFactor": [0.9, 0.9, 0.95, 1], "metallicFactor": 1, "roughnessFactor": 0.4}},
}


class Scene:
    def __init__(self):
        self.blob, self.views, self.accs, self.meshes, self.nodes = bytearray(), [], [], [], []
        self.used = list(MATERIALS)

    def add(self, fmt, values, comp, typ, target, bounds=False):
        off = len(self.blob)
        flat_values = [x for v in values for x in (v if isinstance(v, (tuple, list)) else [v])]
        self.blob.extend(struct.pack("<" + fmt * len(flat_values), *flat_values))
        while len(self.blob) % 4:
            self.blob.append(0)
        self.views.append({"buffer": 0, "byteOffset": off, "byteLength": len(self.blob) - off, "target": target})
        acc = {"bufferView": len(self.views) - 1, "componentType": comp, "count": len(values), "type": typ}
        if bounds:
            acc["min"] = [min(v[k] for v in values) for k in range(3)]
            acc["max"] = [max(v[k] for v in values) for k in range(3)]
        self.accs.append(acc)
        return len(self.accs) - 1

    def mesh(self, pos, nrm, idx, material):
        p, n, i = self.add("f", pos, 5126, "VEC3", 34962, True), self.add("f", nrm, 5126, "VEC3", 34962), self.add("I", idx, 5125, "SCALAR", 34963)
        self.meshes.append({"primitives": [{"attributes": {"POSITION": p, "NORMAL": n}, "indices": i, "material": self.used.index(material)}]})
        self.nodes.append({"mesh": len(self.meshes) - 1})

    def quad(self, a, b, c, d, up, material):
        self.mesh(*quad(a, b, c, d, up), material)

    def shell(self, lo, hi, walls):
        """Inward-facing room; `walls` maps floor/ceiling/back/front/left/right to a material (None leaves the face out)."""
        (x0, y0, z0), (x1, y1, z1) = lo, hi
        faces = {
            "floor": ((x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1), (0, 1, 0)),
            "ceiling": ((x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1), (0, -1, 0)),
            "back": ((x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (0, 0, 1)),
            "front": ((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), (0, 0, -1)),
            "left": ((x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0), (1, 0, 0)),
            "right": ((x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0), (-1, 0, 0)),
        }
        for name, (*corners, up) in faces.items():
            if walls[name]:
                self.quad(*corners, up, walls[name])

    def cuboid(self, lo, hi, material, yaw=0.0):
        """Outward-facing box, turned by `yaw` about its own vertical axis."""
        (x0, y0, z0), (x1, y1, z1) = lo, hi
        cx, cz, c, s = (x0 + x1) / 2, (z0 + z1) / 2, math.cos(yaw), math.sin(yaw)
        turn = lambda p: (cx + c * (p[0] - cx) + s * (p[2] - cz), p[1], cz - s * (p[0] - cx) + c * (p[2] - cz))  # noqa: E731
        t = lambda v: (c * v[0] + s * v[2], v[1], -s * v[0] + c * v[2])  # noqa: E731
        faces = [
            ((x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1), (0, -1, 0)),
            ((x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1), (0, 1, 0)),
            ((x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (0, 0, -1)),
            ((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), (0, 0, 1)),
            ((x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0), (-1, 0, 0)),
            ((x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0), (1, 0, 0)),
        ]
        for *corners, up in faces:
            self.quad(*[turn(p) for p in corners], t(up), material)

    def ball(self, centre, radius, material):
        sp, sn, si = sphere()
        self.mesh(sp, sn, si, material)
        self.nodes[-1].update({"translation": list(centre), "scale": [radius] * 3})

    def camera(self, eye, target, yfov):
        """Perspective camera at `eye` looking at `target`, y up (the camera looks down its -z)."""
        f = [target[i] - eye[i] for i in range(3)]
        n = math.sqrt(sum(x * x for x in f))
        f = [x / n for x in f]
        r = [f[1] * 0 - f[2] * 1, f[2] * 0 - f[0] * 0, f[0] * 1 - f[1] * 0]  # f x up
        n = math.sqrt(sum(x * x for x in r))
        r = [x / n for x in r]
        u = [r[1] * f[2] - r[2] * f[1], r[2] * f[0] - r[0] * f[2], r[0] * f[1] - r[1] * f[0]]
        m = [[r[0], u[0], -f[0]], [r[1], u[1], -f[1]], [r[2], u[2], -f[2]]]  # columns: right, up, back
        tr = m[0][0] + m[1][1] + m[2][2]
        if tr > 0:
            s = math.sqrt(tr + 1) * 2
            q = [(m[2][1] - m[1][2]) / s, (m[0][2] - m[2][0]) / s, (m[1][0] - m[0][1]) / s, s / 4]
        elif m[0][0] > m[1][1] and m[0][0] > m[2][2]:
            s = math.sqrt(1 + m[0][0] - m[1][1] - m[2][2]) * 2
            q = [s / 4, (m[0][1] + m[1][0]) / s, (m[0][2] + m[2][0]) / s, (m[2][1] - m[1][2]) / s]
        elif m[1][1] > m[2][2]:
            s = math.sqrt(1 + m[1][1] - m[0][0] - m[2][2]) * 2
            q = [(m[0][1] + m[1][0]) / s, s / 4, (m[1][2] + m[2][1]) / s, (m[0][2] - m[2][0]) / s]
        else:
            s = math.sqrt(1 + m[2][2] - m[0][0] - m[1][1]) * 2
            q = [(m[0][2] + m[2][0]) / s, (m[1][2] + m[2][1]) / s, s / 4, (m[1][0] - m[0][1]) / s]
        self.nodes.append({"camera": 0, "translation": list(eye), "rotation": q})
        self.yfov = yfov

    def write(self, path):
        gltf = {
            "asset": {"version": "2.0", "generator": "scripts/gen_indirect_scene.py"},
            "extensionsUsed": ["KHR_materials_ior", "KHR_materials_emissive_strength"],
            "scene": 0, "scenes": [{"nodes": list(range(len(self.nodes)))}], "nodes": self.nodes, "meshes": self.meshes,
            "materials": [MATERIALS[k] for k in self.used],
            "cameras": [{"type": "perspective", "perspective": {"yfov": self.yfov, "znear": 0.05, "aspectRatio": 4 / 3}}],
            "buffers": [{"byteLength": len(self.blob), "uri": "data:application/octet-stream;base64," + base64.b64encode(bytes(self.blob)).decode()}],
            "bufferViews": self.views, "accessors": self.accs,
        }
        with open(path, "w") as f:
            json.dump(gltf, f, separators=(",", ":"))


def indoor():
    s = Scene()
    s.shell((-6, 0, -4), (6, 3, 4), {"floor": "wood", "ceiling": "white", "back": "white", "front": "white", "left": "yellow", "right": "blue"})
    # Divider at x = 0 with a doorway (z in -0.6..0.6, up to 2.2) and a lintel above it.
    s.cuboid((-0.1, 0, -4), (0.1, 3, -0.6), "white")
    s.cuboid((-0.1, 0, 0.6), (0.1, 3, 4), "white")
    s.cuboid((-0.1, 2.2, -0.6), (0.1, 3, 0.6), "white")
    s.quad((-4, 2.99, -1), (-2, 2.99, -1), (-2, 2.99, 1), (-4, 2.99, 1), (0, -1, 0), "light")
    s.cuboid((2.5, 0, -3.2), (4.2, 1.0, -1.6), "red", yaw=0.4)
    s.cuboid((3.6, 0, 0.6), (4.6, 1.8, 1.6), "green", yaw=-0.3)
    s.cuboid((-4.5, 0, -3.2), (-3.0, 0.8, -2.0), "white")
    s.ball((2.2, 0.6, 1.4), 0.6, "metal")
    s.camera((5.6, 1.5, 3.6), (1.0, 1.0, -1.2), 1.0)
    return s


def cornell_diffuse():
    s = Scene()
    s.shell((-2, -2, -2), (2, 2, 2), {"floor": "white", "ceiling": "white", "back": "white", "front": None, "left": "red", "right": "green"})
    s.quad((-0.6, 1.99, -0.6), (0.6, 1.99, -0.6), (0.6, 1.99, 0.6), (-0.6, 1.99, 0.6), (0, -1, 0), "light")
    s.cuboid((-1.4, -2, -1.2), (-0.2, 0.2, 0.0), "white", yaw=0.3)
    s.cuboid((0.3, -2, 0.1), (1.3, -0.7, 1.1), "white", yaw=-0.35)
    s.camera((0, 0, 6), (0, 0, 0), 0.9)
    return s


if __name__ == "__main__":
    {"indoor": indoor, "cornell_diffuse": cornell_diffuse}[sys.argv[1]]().write(sys.argv[2])
