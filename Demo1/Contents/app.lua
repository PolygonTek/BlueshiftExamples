local blueshift = require "blueshift"
local admob = require "admob"
local App = blueshift.App

-- ad app ID
local app_id = ""

-- ad unit ID
local banner_ad_unit_id = ""
local interstitial_ad_unit_id = ""
local reward_based_video_ad_unit_id = ""

-- multiple test devices can be specified with a space
local test_devices = "684e00567d950ffd10f284ce38d1eaa2 4E44374435FD7BD8DF6DE503E5686EF6"

function start()
	if admob ~= true then
		if Common.platform_id() == Common.PlatformId.IOS then
			app_id = "ca-app-pub-8691944154836201~8714089961"
			banner_ad_unit_id = "ca-app-pub-8691944154836201/7009291903"
			interstitial_ad_unit_id = "ca-app-pub-8691944154836201/4774844951"
		elseif Common.platform_id() == Common.PlatformId.Android then
			app_id = "ca-app-pub-8691944154836201~2148681616"
			banner_ad_unit_id = "ca-app-pub-8691944154836201/4383128566"
			interstitial_ad_unit_id = "ca-app-pub-8691944154836201/4925575110"
		end

		-- initialize Google mobile ads SDK
		admob.init(app_id, test_devices)

		initBannerAd()
		initInterstitialAd()
	end

	App.load_map("Contents/Maps/main.map");
end

function initBannerAd()
	local BannerAd = admob.BannerAd

	BannerAd.on_loaded = function()
		blueshift.log("BannerAd.on_loaded")
		--BannerAd.show(false, 0, 0)
	end
	BannerAd.on_failed_to_load = function(msg)
		blueshift.log("BannerAd.on_failed_to_load: "..msg)
	end
	BannerAd.on_opening = function()
		blueshift.log("BannerAd.on_opening")
	end
	BannerAd.on_closed = function()
		blueshift.log("BannerAd.on_closed")
	end		
	BannerAd.on_leaving_application = function()
		blueshift.log("BannerAd.on_leaving_application")
	end

	BannerAd.init()
	BannerAd.request(banner_ad_unit_id, -1, 50)
end

function initInterstitialAd()
	local InterstitialAd = admob.InterstitialAd

	InterstitialAd.on_loaded = function()
		blueshift.log("InterstitialAd.on_loaded")
	end
	InterstitialAd.on_failed_to_load = function(msg)
		blueshift.log("InterstitialAd.on_failed_to_load: "..msg)
	end
	InterstitialAd.on_opening = function()
		blueshift.log("InterstitialAd.on_opening")
	end
	InterstitialAd.on_closed = function()
		blueshift.log("InterstitialAd.on_closed")

		-- request again
		InterstitialAd.request(interstitial_ad_unit_id)
	end		
	InterstitialAd.on_leaving_application = function()
		blueshift.log("InterstitialAd.on_leaving_application")
	end

	InterstitialAd.init()
	InterstitialAd.request(interstitial_ad_unit_id)
end