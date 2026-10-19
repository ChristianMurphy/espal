import Lake

open Lake DSL

package «routing-serve»

require routing from git
  "https://github.com/paulbutcher/lean-routing"@"75d8bc32eb9d53bd970d5a97e41f4863b462c614"

@[default_target] lean_exe «router-serve» where root := `RouterServe
