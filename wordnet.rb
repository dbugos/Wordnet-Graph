class WordNet

# Building the WordNet graph: each vertex v is a non-negative
# integer that represents a synset, and each directed edge v->w
# represents that w is a hypernym of v. The graph is directed
# and acyclic (DAG), though not necessarily a tree since each
# synset can have several hypernyms

  def initialize(file1, file2)
    @synsets = Hash.new
    @hypernyms = Hash.new

    @invalid_synsets = Array.new
    @invalid_hypernyms = Array.new

    get_synsets(file1)
    get_hypernyms(file2)

    if @invalid_synsets.length > 0
      puts "invalid synsets"
      @invalid_synsets.each { |x| puts x}
      exit
    end

    if @invalid_hypernyms.length > 0
      puts "invalid hypernyms"
      @invalid_hypernyms.each { |x| puts x}
      exit
    end
  end

  def get_synsets(file)
    f = File.open(file)
    line = f.gets
    while line != nil
      line.chomp!
      if /(^id: \d+ synset: .*\w+(,\w+)*\s?)/ !~ line 
        @invalid_synsets.push(line)
      else
        arr = line.split(" ")
        key = arr[1].to_i
        values = arr[3].split(",")
        @synsets[key] = values
      end
      line = f.gets
    end
    f.close
  end

  def get_hypernyms(file)
    f = File.open(file)    
    line = f.gets
    while line != nil
      if /(^from: \d+ to: \d+(,\d+)*\s?)/ !~ line
        @invalid_hypernyms.push(line)
      else
        arr = line.split(" ")
        key = arr[1].to_i
        values = arr[3].split(",").map(&:to_i)
        if @hypernyms[key] == nil
          @hypernyms[key] = values
        else
          @hypernyms[key] = @hypernyms[key] + values
        end
      end
      line = f.gets
    end
    f.close
  end




# The provided code will process the input file and pass an
# array of words into isnoun. The method should return true
# if all of the words in the array are contained in the
# synsets, and false otherwise
  def isnoun(arr)
    bool = false
    arr.each do |noun|
      @synsets.each do |key, values|
        bool = values.include?(noun)
        if bool == true
          break
        end
      end
      if bool == false
        break
      end
    end
    bool
  end




# Returns the number of nouns in the synsets. The count should
# also include all instances of duplicate nouns.
  def nouns
    i = 0
    @synsets.each do |key, values|
      i += values.length
    end
    i
  end




# Returns the number of edges in the WordNet graph built from the hypernyms
  def edges
    i = 0
    @hypernyms.each do |key, values|
      i += values.length
    end
    i
  end




 # Let v and w be defined as sets (arrays) of synset IDs.
 # Returns minimum length of the SAPs between any ID of v
 # and any ID of w
  def length(v, w)
   all_ancestors = []
   min_dst = Float::INFINITY
   v.each do |a|
     w.each do |b|
       all_ancestors.push(lowest_common_ancestor(a, b))
     end
   end
 
   ancestor_exists = false

   all_ancestors.each do |arr|
     ancestor_exists = true if arr[0] != nil
     curr_dst = arr[1]
     min_dst = curr_dst if curr_dst < min_dst
   end

   ancestor_exists ? min_dst : -1
  end




# Let v and w be defined as above. The method will first find
# the minimum-length SAPs between the IDs of v and w. Then, it
# should return an array of the SAPs' LCAs (in any order). The
# array should not contain duplicates
  def ancestor(v, w)
   all_ancestors = []
   min_dst = Float::INFINITY
   lcas = []
   v.each do |a|
     w.each do |b|
       all_ancestors.push(lowest_common_ancestor(a, b))
     end
   end
   ancestor_exists = false
   all_ancestors.each do |arr|
     ancestor_exists = true if arr[0].size > 0
     curr_dst = arr[1]
     if curr_dst < min_dst
       min_dst = curr_dst 
       lcas = arr[0]
     elsif curr_dst == min_dst
       lcas += arr[0]
     end
   end
   ancestor_exists ? lcas : -1
  end




# Let v and w each be a noun. Let v' and w' represent the synset
# IDs associated with the nouns v and w respectively. Returns an
# array (any order) of the nouns contained in the LCAs of v' and
# w', including duplicates
  def root(v, w)
    v_ids = []
    w_ids = []
    roots = []

    @synsets.each do |key, value|
      if value.include?(v)
        v_ids.push(key)
      end
      if value.include?(w)
        w_ids.push(key)
      end
    end

    lcas = ancestor(v_ids, w_ids)
    if lcas == -1
      return -1
    else
      lcas.each do |a|
        roots += @synsets[a]
      end
    end
    return roots
  end




# Given a list of nouns A1, A2, ..., An, which noun is the least
# related to the others? To identify the outcast, for each noun 
# compute the sum of the squares of the distance between the noun 
# and every other one. For instance, the sum for noun Ai (denoted
# as di) is calculated as follows:

# di = (dist(Ai, A1))2 + (dist(Ai, A2))2 + ... + (dist(Ai, An))2. 
# The outcast(s) is At for which dt is the maximum

# Given an array of nouns, the method should return an array of the outcast(s)
  def outcast(nouns)
    ids = {}
    distances = {}
    max_dst = -1.0/0.0
    nouns.each do |n|
      @synsets.each do |key, value|
        if value.include?(n)
          if ids[n] == nil
            ids[n] = [key]
          else
            if !ids[n].include?(key)
              ids[n].push(key)
            end
          end
        end
      end
    end

    id_arr = ids.to_a

    i = 0
    while i < id_arr.size
      j = 0
      while j < id_arr.size
        distances[[id_arr[i][0], id_arr[j][0]]] = length(id_arr[i][1], id_arr[j][1])
        j += 1
      end
      i += 1
    end

    i = 0
    total_distances = {}
    while i < nouns.size
      j = 0
      dst = 0
      while j < nouns.size
        l = distances[[nouns[i], nouns[j]]]
        
          dst += l*l
        
        j += 1
      end
      if dst > max_dst
        max_dst = dst
      end
      if !total_distances.include?(nouns[i])
        total_distances[nouns[i]] = dst
      end
      i += 1
    end

    outcasts = []
    total_distances.each do |k, v|
      if v == max_dst
        for i in 1..num_occurrences(nouns, k)
          outcasts.push(k)
        end
      end
    end
    outcasts
  end
  
  def num_occurrences(arr, item)
    count = 0
    arr.each do |a|
      if a == item
        count += 1
      end
    end
    count
  end

# Performs a binary search starting at the input vertex
# Returns a hash of distances, in which the key is the
# vertex ID, and the value is that vertex's dist to src
# vertex v. 
  def bfs(v)
    curr = v
    queue = []
    distances = Hash.new(0)
    queue.push(curr)
    distances[curr] = 0
    while !queue.empty?
      curr = queue.shift
      dst = distances[curr] + 1
      if @hypernyms.include?(curr)
        queue += @hypernyms[curr]
      end
      queue.each do |v|
        
        distances[v] = dst if !distances.include?(v)
      end
    end
    distances
  end

# Returns the lowest common ancestor between vertex
# a and b, and the combined distance of each vertex
# to that ancestor
  def lowest_common_ancestor(a, b)
    neighbors_A = bfs(a)
    neighbors_B = bfs(b)

    min_dst = Float::INFINITY

    in_common = neighbors_A.keys & neighbors_B.keys
    lcas = []
    
    in_common.each do |v|
      curr_dst = neighbors_A[v] + neighbors_B[v] 
      if curr_dst < min_dst
        min_dst = curr_dst
        lcas.clear
        lcas.push(v)
      elsif curr_dst == min_dst
        lcas.push(v)
      end
    end
    if min_dst == Float::INFINITY
      min_dst = -1
    end
    return [lcas, min_dst]
  end

end
  

#If the result is an array, then the array's contents will be printed in a sorted and space-delimited string. 
#Otherwise, the result is printed as-is
def print_res(res)
    if (res.instance_of? Array) then 
        str = ""
        res.sort.each {|elem| str += elem.to_s + " "}
        puts str.chomp
    else 
        puts res
    end
end 

#Checks that the user has provided an appropriate amount of arguments
if (ARGV.length < 3 || ARGV.length > 5) then
  fail "usage: wordnet.rb <synsets file> <hypersets file> <command> <input file>"
end

synsets_file = ARGV[0]
hypernyms_file = ARGV[1]
command = ARGV[2]
input_file = ARGV[3]

wordnet = WordNet.new(synsets_file, hypernyms_file)

#Refers to number of lines in input file
commands_with_0_input = %w(edges nouns)
commands_with_1_input = %w(isnoun outcast)
commands_with_2_input = %w(length ancestor)

#Executes the program according to the provided mode
case command
when *commands_with_0_input
	puts wordnet.send(command)
when *commands_with_1_input 
	file = File.open(input_file)
	nouns = file.gets.split(/\s/)
	file.close    
    print_res(wordnet.send(command, nouns))
when *commands_with_2_input 
	file = File.open(input_file)   
	v = file.gets.split(/\s/).map(&:to_i)
	w = file.gets.split(/\s/).map(&:to_i)
	file.close
    print_res(wordnet.send(command, v, w))
when "root"
	file = File.open(input_file)
	v = file.gets.strip
	w = file.gets.strip
	file.close
    print_res(wordnet.send(command, v, w))
else
  fail "Invalid command"
end
