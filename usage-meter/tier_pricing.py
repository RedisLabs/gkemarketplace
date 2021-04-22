tiers = [
'small_node_time',
'small_high_memory_node_time',
'medium_high_memory_node_time',
'large_high_memory_node_time',
'extra_large_high_memory_node_time'
]
cpu_tiers = [32,16,8,4,0]
memory_tiers = [208,104,52,26,0]

def tier_from_usage(data):
   tier = 0
   cpu = data.get('cpu')
   for index, value in enumerate(cpu_tiers):
      if cpu >= value:
         tier = max(tier,len(tiers)-index-1)
   memory = data.get('memory')
   for index, value in enumerate(memory_tiers):
      if memory >= value:
         tier = max(tier,len(tiers)-index-1)
   return tiers[tier]
