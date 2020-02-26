globals = {"journal","modutil"}

read_globals = {
	"dump",
	"minetest",
	"vector",
	"VoxelManip",
	"VoxelArea",
	"ItemStack",
}

files["journal/init.lua"].read_globals = {
	"betterinv", "sfinv_buttons", "sfinv", "unified_inventory"
}

ignore = {
	"211",
	"212",
	"213",
	"611",
	"612",
	"631"
}
