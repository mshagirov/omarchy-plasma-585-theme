local active = { colors = { "rgba(ffd58aff)", "rgba(c59659ff)" }, angle = 45 }
local inactive = "rgba(63513bff)"
hl.config({
  general = { col = { active_border = active, inactive_border = inactive } },
  group = { col = { border_active = active, border_inactive = inactive } },
  decoration = {
    rounding = 5,
    shadow = {
      enabled = true,
      range = 22,
      render_power = 3,
      color = "rgba(ffbf6638)",
      color_inactive = "rgba(d6984014)",
    },
  },
})
