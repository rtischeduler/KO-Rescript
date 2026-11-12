robo=script.Parent:clone()

while true do
	wait()
	if script.Parent ~= nil then
	if script.Parent.Zombie.Health <= 1  then
		wait(3)
		robot=robo:clone()
		robot.Parent=script.Parent.Parent
		robot:makeJoints()
		script.Parent:remove()
	end
	end
end
		


