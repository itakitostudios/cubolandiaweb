class_name AvatarCubo
extends RefCounted

static var catalogo := {}

const BASE := {
	"cabeza": "#f5cd30", "torso": "#0d66b3", "brazoI": "#f5cd30",
	"brazoD": "#f5cd30", "piernaI": "#4d9a4d", "piernaD": "#4d9a4d"
}

const PARTES := {
	"torso": {"o": [0, 3, 0], "t": [2, 2, 1], "d": [0, 0, 0]},
	"cabeza": {"o": [0, 4.6, 0], "t": [1.2, 1.2, 1.2], "d": [0, 0, 0]},
	"brazoI": {"o": [-1.5, 4, 0], "t": [1, 2, 1], "d": [0, -1, 0]},
	"brazoD": {"o": [1.5, 4, 0], "t": [1, 2, 1], "d": [0, -1, 0]},
	"piernaI": {"o": [-0.5, 2, 0], "t": [1, 2, 1], "d": [0, -1, 0]},
	"piernaD": {"o": [0.5, 2, 0], "t": [1, 2, 1], "d": [0, -1, 0]}
}

const CARA_BASE := [
	{"tam": [0.15, 0.25, 0.05], "pos": [-0.25, 0.15, -0.61], "color": "#1a1a1a"},
	{"tam": [0.15, 0.25, 0.05], "pos": [0.25, 0.15, -0.61], "color": "#1a1a1a"},
	{"tam": [0.5, 0.08, 0.05], "pos": [0, -0.25, -0.61], "color": "#1a1a1a"},
	{"tam": [0.1, 0.1, 0.05], "pos": [-0.28, -0.18, -0.61], "color": "#1a1a1a"},
	{"tam": [0.1, 0.1, 0.05], "pos": [0.28, -0.18, -0.61], "color": "#1a1a1a"}
]

static func v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

static func color_de(hex, defecto: Color) -> Color:
	var s := str(hex)
	if Color.html_is_valid(s):
		return Color.html(s)
	return defecto

static func caja(padre: Node3D, tam: Array, pos: Array, color: Color):
	var malla := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = v3(tam)
	malla.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	malla.material_override = m
	malla.position = v3(pos)
	padre.add_child(malla)

# Dibuja el personaje dentro de "padre" y devuelve las piezas que se mueven al caminar
static func construir(padre: Node3D, colores: Dictionary, equipado: Dictionary) -> Dictionary:
	var col := {}
	for k in BASE.keys():
		col[k] = color_de(colores.get(k, BASE[k]), Color.WHITE)

	var items: Array = []
	for tipo in ["camisa", "pantalon", "sombrero", "cara"]:
		var id = equipado.get(tipo, null)
		if id != null and catalogo.has(str(id)):
			items.append(catalogo[str(id)])

	for it in items:
		var p: Dictionary = it.get("params", {})
		var c: Dictionary = p.get("colores", {})
		for k in c.keys():
			if col.has(k):
				col[k] = color_de(c[k], col[k])

	var nodos := {}
	for nombre in PARTES.keys():
		var def: Dictionary = PARTES[nombre]
		var piv := Node3D.new()
		piv.position = v3(def["o"])
		padre.add_child(piv)
		nodos[nombre] = piv
		caja(piv, def["t"], def["d"], col[nombre])

	var cara_propia := false
	for it in items:
		var p: Dictionary = it.get("params", {})
		if p.get("reemplaza_cara", false):
			cara_propia = true
		for c in p.get("cajas", []):
			var destino: Node3D = nodos.get(str(c.get("en", "")), padre)
			caja(destino, c["tam"], c["pos"], color_de(c.get("color", "#ffffff"), Color.WHITE))
	if not cara_propia:
		for c in CARA_BASE:
			caja(nodos["cabeza"], c["tam"], c["pos"], color_de(c["color"], Color.BLACK))

	return {
		"bi": nodos["brazoI"], "bd": nodos["brazoD"],
		"pi": nodos["piernaI"], "pd": nodos["piernaD"]
	}
