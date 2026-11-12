gw=game.Workspace

function message(text,time)
	wait(10)
end

last=""
lastlast=""
while true do
	wait(10)
	local tracks=script:GetChildren()
	local rn=math.random(1,#tracks)
	local track=tracks[rn]
	if track~=nil then
		if track.className=="Sound" and track.Name~=last and track.Name~=lastlast then
			lastlast=last
			last=track.Name
			message(track.Name,10)
			track:play()
			wait(15.7)
			track:pause()
		end
	end
end
	