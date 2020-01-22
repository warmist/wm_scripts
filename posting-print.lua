for i,v in ipairs(df.global.world.jobs.postings) do
	if not v.flags.dead and v.job.job_type==df.job_type.GatherPlants then
		print(i)
	end
end