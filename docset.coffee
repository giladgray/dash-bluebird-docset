fs        = require 'fs'            # file loading
hljs      = require 'highlight.js'  # syntax highlighting
marked    = require 'marked'        # markdown compilation
cheerio   = require 'cheerio'       # html parsing
Sequelize = require 'sequelize'     # db building

NAME = 'bluebird.docset'
PATH = "#{NAME}/Contents/Resources/Documents"

# compile API.md to HTML
marked.setOptions
  gfm: true
  breaks: true
  highlight: (code, lang) ->
    (if lang then hljs.highlight(lang, code) else hljs.highlightAuto(code)).value
fs.writeFileSync "html/api.html", """
<html>
  <head>
    <link rel="stylesheet" href="github-markdown.css">
    <link rel="stylesheet" href="github-highlight.css">
  </head>
  <body>
    <div class="markdown-body">#{marked(fs.readFileSync('html/API.md', 'utf8'))}<div>
  </body>
</html>
"""
# copy CSS files
fs.writeFileSync "#{PATH}/github-markdown.css",
  fs.readFileSync('node_modules/github-markdown-css/github-markdown.css')
fs.writeFileSync "#{PATH}/github-highlight.css",
  fs.readFileSync('node_modules/highlight.js/styles/github.css')

console.log 'Generated HTML from API.md and copied CSS files.'

# HTML Guides, saved from http://handlebarsjs.com
FILES = {
  'API' : 'api.html'
}

# sections that don't have any functions and should get /0 anchor
SOLOS = ['#progression-migration', '#deferred-migration'].join(', ')

# type: {name: path, ...}
docset =
  Section: {}
  Function: {}

# populate the given entry type with this element
populateEntry = (file, type) -> ->
  $el   = $(@)
  title = $el.text().trim()
  docset[type][title] = "#{file}##{$el.attr('id')}"
  level = if $el.is('h2') then 1 else 0
  title = encodeURIComponent(title)
  # insert table of contents anchor before this element
  $el.before "<a name='//dash_ref/#{type}/#{title}/#{level}' class='dashAnchor'></a>\n"
  if $el.is(SOLOS)
    $el.before "<a name='//dash_ref/#{type}/#{title}/0' class='dashAnchor'></a>\n"

for title, file of FILES
  $ = cheerio.load fs.readFileSync("html/#{file}")
  # discover docset entries
  $('h2').each populateEntry(file, 'Section')
  $('h5').each populateEntry(file, 'Function')
  # standardize page <title> and <h1> tags
  $('title').text(title)
  unless $('h1').length
    $('#contents').prepend "<h1>#{title}</h1>"
  # write modified HTML to docset contents
  fs.writeFileSync "#{PATH}/#{file}", $.html()

console.log 'Docset Configuration:'
console.log docset
console.log '\n'

# create the database!
db = new Sequelize 'database', 'username', 'password',
  dialect: 'sqlite'
  storage: "#{NAME}/Contents/Resources/docSet.dsidx"

# create the SearchIndex table, per http://kapeli.com/docsets
SearchIndex = db.define 'searchIndex',
  id:
    type: Sequelize.INTEGER
    autoIncrement: true
    primaryKey: true
  name: Sequelize.STRING
  type: Sequelize.STRING
  path: Sequelize.STRING
,
  freezeTableName: true
  timestamps: false

# recreate the table and populate it from docset object
db.sync(force: true)
  .complete ->
    for type, data of docset
      for name, path of data
        SearchIndex.create {name, type, path}
