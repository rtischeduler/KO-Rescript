

return {
	IntName = "MG21", 
	Info = {
		Name = "Mechagodzilla 2021", 
		Description = "Mechagodzilla 2021(\227\131\161\227\130\171\227\130\180\227\130\184\227\131\169) is a robotic doppelganger built by Apex Cybernetics. The project was lead by Walter Simmons, who wanted to use the robot to exterminate the titans. The skull of Monster Zero was linked to Mechagodzilla's supercomputer for its telepathic communicative properties, allowing control from afar; however, with the Hollow Earth energy used as fuel, it reawakened what remained of Ghidorah's consciousness within the skull. Parched for revenge, it went rogue...", 
		Tier = "S+", 
		CanTeam = 0, 
		Year = 2021, 
		Movies = { "Godzilla vs. Kong" }, 
		Era = "MonsterVerse", 
		Height = 122, 
		Length = "Unknown", 
		Weight = "Unknown", 
		Credits = {
			Modelling = "Jonathan Miller", 
			Rigging = "Hurricane", 
			Animating = "Aliens"
		}, 
		Images = {
			Icon = "rbxassetid://7518802523"
		}, 
		Passive = "Press V to dash. Costs 15 charge."
	}, 
	Price = { {
		Name = "350000 G-Cells", 
		AutoOwn = function(p1, p2)
			return false;
		end, 
		IsPurchasable = function(p3, p4, p5)
			return p4:GetPath({ "G-Cells" }) >= 350000;
		end, 
		Purchase = function(p6, p7)
			p7:SetPath({ "G-Cells" }, p7:GetPath({ "G-Cells" }) - 350000);
		end
	}, {
		Name = "Level 50 Kong 2021", 
		AutoOwn = function(p8, p9)
			return false;
		end, 
		IsPurchasable = function(p10, p11, p12)
			return p11:GetPath({ "Kaijus", "Kong2021", "Level" }) >= 50;
		end, 
		Purchase = function(p13, p14)

		end
	}, {
		Name = "Level 50 Godzilla 2021", 
		AutoOwn = function(p15, p16)
			return false;
		end, 
		IsPurchasable = function(p17, p18, p19)
			return p18:GetPath({ "Kaijus", "Godzilla2021", "Level" }) >= 50;
		end, 
		Purchase = function(p20, p21)

		end
	} }, 
	Camera = {
		LockOffset = Vector3.new(17, 20, 65)
	}, 
	Health = {
		Rate = 1.01, 
		Base = 5000, 
		Max = 6250
	}, 
	Charge = {
		Rate = 1.03, 
		Max = 100
	}, 
	Stamina = {
		Rate = 1.03, 
		Max = 100
	}, 
	Level = {
		Max = 100, 
		XpPerLevel = 62, 
		Badge = ""
	}, 
	Resistances = {
		Fire = 0.8, 
		Frozen = 1, 
		Slash = 0.9, 
		Impact = 1, 
		Puncture = 1.1, 
		Energy = 0.9
	}, 
	States = {
		Idling = {
			Animation = "rbxassetid://7128403071"
		}, 
		Walking = {
			Speed = 14, 
			Sound = {
				Id = "rbxassetid://7283841770"
			}, 
			Animation = "rbxassetid://7755918712"
		}, 
		Sprinting = {
			Speed = 27, 
			Animation = "rbxassetid://7755916163"
		}, 
		Swimming = {
			Speed = 90, 
			Animation = "rbxassetid://7128404855"
		}, 
		Death = {
			Animation = "rbxassetid://7128401408", 
			Sound = {
				Id = "rbxassetid://10749097971"
			}
		}
	}, 
	Roars = { {
		Info = {
			Name = "Rival Roar", 
			Description = "Currently has no effect.", 
			Images = {
				Button = "rbxassetid://7129077989"
			}
		}, 
		Sound = {
			Id = "rbxassetid://7128678478"
		}, 
		Drain = { "Charge", 40 }, 
		Cooldown = 300, 
		Effects = {}, 
		Animation = {
			Time = 4.6, 
			Id = "rbxassetid://7128406624"
		}
	}, {
		Info = {
			Name = "Maniacal Cackle", 
			Description = "Currently has no effect.", 
			Images = {
				Button = "rbxassetid://7129078545"
			}
		}, 
		Sound = {
			Id = "rbxassetid://7128678429"
		}, 
		Drain = { "Charge", 80 }, 
		Cooldown = 150, 
		Effects = {}, 
		Animation = {
			Time = 2.3, 
			Id = "rbxassetid://7128407800"
		}
	} }, 
	Attacks = { {
		Info = {
			Name = "Turbo Strike", 
			Description = "Imbue your right fist with Hollow Earth energy, and unleash a devastating punch.", 
			Type = { "Melee", "Energy" }, 
			Images = {
				Button = "rbxassetid://7129078131"
			}
		}, 
		AttackDamage = {
			Base = 475, 
			Max = 695
		}, 
		Effects = {}, 
		Knockback = 25, 
		Drain = { "Stamina", 12.5 }, 
		Cooldown = 1.7, 
		Animation = {
			Time = 2.64, 
			Id = "rbxassetid://7140944764"
		}
	}, {
		Info = {
			Name = "Invigorated Kick", 
			Description = "Dash forwards and stomp the ground with immeasurable force, dealing damage in a large radius.", 
			Type = { "Pulse", "Impact" }, 
			Images = {
				Button = "rbxassetid://7129078696"
			}
		}, 
		AttackDamage = {
			Base = 520, 
			Max = 740
		}, 
		Effects = {}, 
		Knockback = 40, 
		Drain = { "Stamina", 20 }, 
		Cooldown = 5, 
		Range = 220, 
		Duration = 0.7, 
		Animation = {
			Time = 1.9500000000000002, 
			Id = "rbxassetid://7128397236"
		}
	}, {
		Info = {
			Name = "Surgical Stab", 
			Description = "Active your trail drill and repeatedly stab a stab in front of you.", 
			Type = { "Melee", "Puncture" }, 
			Images = {
				Button = "rbxassetid://7129077848"
			}
		}, 
		AttackDamage = {
			Base = 585, 
			Max = 815.4
		}, 
		Effects = {}, 
		Knockback = 10, 
		Drain = { "Stamina", 15 }, 
		Cooldown = 3, 
		Animation = {
			Time = 2.7, 
			Id = "rbxassetid://7128398221"
		}
	}, {
		Info = {
			Name = "Proton Scream", 
			Description = "Fire off a concentrated beam of pure protons, melting anything it touches.", 
			Type = { "Beam", "Fire" }, 
			Images = {
				Button = "rbxassetid://7129078255"
			}
		}, 
		AttackDamage = {
			Base = 1550, 
			Max = 2550
		}, 
		Effects = {}, 
		Knockback = 10, 
		Drain = { "Charge", 60 }, 
		Cooldown = 30, 
		Duration = 6, 
		Animation = {
			Time = 15.3, 
			Id = "rbxassetid://7128399219"
		}
	}, {
		Info = {
			Name = "Creeping Salvo", 
			Description = "Fire off a massive salvo of 8 missiles. Missiles track your mouse/finger position for the first second.", 
			Type = { "Projectile", "Impact" }, 
			Images = {
				Button = "rbxassetid://7129078392"
			}
		}, 
		AttackDamage = {
			Base = 60, 
			Max = 95
		}, 
		Effects = {}, 
		Knockback = 10, 
		Drain = { "Charge", 30 }, 
		Cooldown = 14, 
		Duration = 5, 
		Animation = {
			Time = 2, 
			Id = "rbxassetid://7128400466"
		}
	} }
};
