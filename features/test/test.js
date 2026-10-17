const Ajv = require('ajv')
const fs = require('fs')
const yaml = require('yaml')
const ajv = new Ajv({
  allErrors: true,
})

let allValid = true
fs.readdirSync('.').forEach(file => {
    if (file.endsWith('.yaml')) {
      const schemaFile = `schema/${file}`
      const schema = yaml.parse(fs.readFileSync(schemaFile, {encoding: 'utf-8'}))
      const validate = ajv.compile(schema)

      const data = yaml.parse(fs.readFileSync(file, {encoding: 'utf-8'}))

      const valid = validate(data)

      if (valid) {
        console.info(`File ${file} validated by schema ${schemaFile} is valid.`)
      } else {
        const formattedErrors = validate.errors.map(({instancePath, keyword, message, params}) => `- Path ${instancePath} [${keyword}]: ${message} (details: ${JSON.stringify(params)})`)
        console.error(`File ${file} validated by schema ${schemaFile} is invalid:\n${formattedErrors.join('\n')}`)
        allValid = false
      }
    }
  }
)

if (allValid) {
  console.info("All files are valid ✅")
} else {
  console.error("There were validation errors ❌")
}

process.exit(allValid ? 0 : 1);
