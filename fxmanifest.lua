fx_version "cerulean"

lua54 'yes'

games {
  "gta5",
  "rdr3"
}

ui_page 'web/build/index.html'

client_script "client/**/cl_*.lua"
shared_script "shared/**/sh_*.lua"

files {
	'web/build/index.html',
	'web/build/**/*',
}