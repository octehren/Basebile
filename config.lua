application =
{

	content =
	{
		width = 320,
		height = 480, 
		scale = "adaptative",
		fps = 60,
		
		imageSuffix =
		{
			    ["@2x"] = 1.5,
				["@3x"] = 2
		},
	},

	--[[
	-- Push notifications
	notification =
	{
		iphone =
		{
			types =
			{
				"badge", "sound", "alert", "newsstand"
			}
		}
	},
	--]]    
}
