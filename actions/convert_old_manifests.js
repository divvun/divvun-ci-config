const TOML = require('@iarna/toml')
const path = require("path")
const fs = require("fs")

async function run() {
    const repoPath = process.argv[2]
    console.log(repoPath)

    const oldManifest = TOML.parse(fs.readFileSync(path.join(repoPath, ".gut", "manifest.toml"), "utf8"))

    const newManifest = {
        name: oldManifest.package.human_name,
        version: oldManifest.package.version,
        macos: {
            system_pkg_id: oldManifest.bundles.speller_macos.pkg_id
        },
        windows: {
            system_product_code: oldManifest.bundles.speller_win.uuid,
            msoffice_product_code: oldManifest.bundles.speller_win_mso.uuid
        }
    }
    
    fs.writeFileSync(path.join(repoPath, "manifest.toml"), TOML.stringify(newManifest), "utf8")
    newManifest.version = "@SPELLERVERSION@"
    fs.writeFileSync(path.join(repoPath, "manifest.toml.in"), TOML.stringify(newManifest), "utf8")
}

run().catch(err => {
    console.error(err.stack)
    process.exit(1)
})
