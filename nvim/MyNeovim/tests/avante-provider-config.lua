local test_path = debug.getinfo(1, "S").source:sub(2)
local myneovim_root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(test_path)))
local config_path = vim.fs.joinpath(myneovim_root, "lua", "plugins", "avante.lua")
local spec = assert(loadfile(config_path))()

local codex = assert(spec.opts.acp_providers.codex)
local codex_args = table.concat(codex.args or {}, "\n")
assert(codex_args:find('model="gpt%-5%.5"', 1, false), "Avante Codex ACP must default to gpt-5.5")
assert(
  codex_args:find('model_reasoning_effort="medium"', 1, false),
  "Avante Codex ACP must keep medium reasoning effort"
)

local cerebras = assert(spec.opts.providers.cerebras)
assert(cerebras.__inherited_from == "openai", "Cerebras must inherit the OpenAI-compatible provider")
assert(cerebras.api_key_name == "CEREBRAS_API_KEY", "Cerebras must use its own API key variable")

local codex_model_values = {}
for _, option in ipairs(spec._codex_acp_model_options()) do
  codex_model_values[option.value] = true
end
assert(codex_model_values["gpt-6-astra"], "Avante ACP model selector must include GPT-6 Astra")
assert(codex_model_values["gpt-5.6"], "Avante ACP model selector must include the current GPT-5.6 alias")

local commands = {}
for _, command in ipairs(spec.cmd or {}) do
  commands[command] = true
end
assert(commands.AvanteACPModels, "Avante ACP model selector command must lazy-load Avante")
assert(commands.AvanteACPModes, "Avante ACP mode selector command must lazy-load Avante")

local has_acp_model_key = false
for _, key in ipairs(spec.keys or {}) do
  if key[1] == "<leader>axM" and key[2] == "<cmd>AvanteACPModels<CR>" then
    has_acp_model_key = true
    break
  end
end
assert(has_acp_model_key, "Avante ACP model selector must have a keymap")

local original_loaded = {}
for name, module in pairs(package.loaded) do
  if name:match("^avante") then
    original_loaded[name] = module
  end
end

local opened_sidebar = false
local delegated_selector = false
local sidebar = {
  containers = {},
  acp_client = {
    config = { command = codex.command },
  },
  is_open = function()
    return false
  end,
}

local ACPClient = {
  _convert_legacy_session_fields = function(self, result)
    if result.configOptions then
      self.config_options = result.configOptions
      self._legacy_api = false
      return
    end
    self.config_options = nil
    self._legacy_api = false
  end,
  set_model = function(self, _, model_id, cb)
    for _, option in ipairs(self.config_options or {}) do
      if option.category == "model" or option.id == "model" then
        option.currentValue = model_id
      end
    end
    cb(self.config_options, nil)
  end,
}

package.loaded["avante"] = {
  get = function()
    return sidebar
  end,
  open_sidebar = function(opts)
    assert(opts and opts.ask == false, "ACP selector must open Avante without submitting a prompt")
    opened_sidebar = true
  end,
  setup = function() end,
}
package.loaded["avante.config"] = {
  provider = "codex",
  acp_providers = { codex = {} },
}
package.loaded["avante.utils"] = {
  warn = function(message)
    error(message)
  end,
  error = function(message)
    error(message)
  end,
  info = function() end,
}
package.loaded["avante.utils.root"] = {
  get = function()
    return vim.fn.getcwd()
  end,
}
package.loaded["avante.sidebar"] = {
  initialize = function() end,
  show_input_hint = function() end,
  setup_window_navigation = function() end,
}
package.loaded["avante.history.render"] = {
  message_to_lines = function()
    return {}
  end,
  message_to_text = function()
    return ""
  end,
}
package.loaded["avante.history.helpers"] = {
  is_tool_use_message = function()
    return false
  end,
}
package.loaded["avante.providers.openai"] = {
  parse_messages = function()
    return {}
  end,
}
package.loaded["avante.libs.acp_client"] = ACPClient
package.loaded["avante.acp_config_selector"] = {
  open = function(category, prompt)
    assert(opened_sidebar, "ACP selector must open Avante before delegating")
    assert(category == "model", "ACP selector category must be preserved")
    assert(prompt == "ACP Agent Models> ", "ACP selector prompt must be preserved")
    delegated_selector = true
  end,
}

spec.config(nil, spec.opts)

local client = {
  config = { command = codex.command },
}
ACPClient._convert_legacy_session_fields(client, { sessionId = "test-session" })
local injected_values = {}
for _, config_option in ipairs(client.config_options or {}) do
  if config_option.category == "model" then
    for _, option in ipairs(config_option.options or {}) do
      injected_values[option.value] = true
    end
  end
end
assert(injected_values["gpt-6-astra"], "ACP client conversion must inject GPT-6 model options")
assert(client._legacy_api == true, "Synthetic Codex ACP model options must use legacy set_model flow")

ACPClient.set_model(client, "test-session", "gpt-6-astra", function(_, err)
  assert(not err, "ACP set_model patch must preserve successful callbacks")
end)
for _, config_option in ipairs(client.config_options or {}) do
  if config_option.category == "model" then
    assert(config_option.currentValue == "gpt-6-astra", "ACP set_model patch must update the current model")
  end
end

package.loaded["avante.acp_config_selector"].open("model", "ACP Agent Models> ")
assert(delegated_selector, "Avante ACP selector patch must delegate to the original selector")
local existing_client_values = {}
for _, config_option in ipairs(sidebar.acp_client.config_options or {}) do
  if config_option.category == "model" then
    for _, option in ipairs(config_option.options or {}) do
      existing_client_values[option.value] = true
    end
  end
end
assert(existing_client_values["gpt-6-astra"], "ACP selector patch must update an existing Codex ACP client")

package.loaded["avante"] = original_loaded["avante"]
package.loaded["avante.acp_config_selector"] = original_loaded["avante.acp_config_selector"]
package.loaded["avante.config"] = original_loaded["avante.config"]
package.loaded["avante.utils"] = original_loaded["avante.utils"]
package.loaded["avante.utils.root"] = original_loaded["avante.utils.root"]
package.loaded["avante.sidebar"] = original_loaded["avante.sidebar"]
package.loaded["avante.history.render"] = original_loaded["avante.history.render"]
package.loaded["avante.history.helpers"] = original_loaded["avante.history.helpers"]
package.loaded["avante.providers.openai"] = original_loaded["avante.providers.openai"]
package.loaded["avante.libs.acp_client"] = original_loaded["avante.libs.acp_client"]

print("avante provider config passed")
