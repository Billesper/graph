defmodule Graph.Algorithm do

  @moduledoc """
  Graph.Algorithm provides general algorithms for searching graphs, 
  checking their properties, and so on.

  Every function takes a Graph.t struct as its first parameter.
  Additionally, many of the algorithms involve specific nodes as inputs,
  and thus take node ids in subsequent parameters.
  """

  # General implementation notes:

  # Most of the search algorithms / algorithms involving search are broken down as follows:
  # 1) a public interface function, and in some cases, an additional function to initialize
  # the algorithm state
  # 2) a recursive "visit" function, centered around a single unvisited input node, that
  # adds the node to the set of visited nodes (with one exception described below),
  # gets the list of nodes adjacent to it, and then calls an "explore" (see 3 below) function
  # based on that list
  # 3) a recursive "explore" function which takes an input list as described above, does something
  # for the head node in the list, and then recurses on the remainder of the list.

  # The only exception to the visit/explore convention of 2)/3) is a slight deviation
  # with bfs_source. bfs_source does not use a visit function, and nodes are added to visited set
  # in an "explore" function, since BFS is generally implemented in this manner.

  # TODO:
  # *Support additional functionality for pre/postorder DFS search 
  # *Support options for the search interface functions to return traversal order and possibly other
  # useful information that can be gleaned from a graph search
  # *Add additional algorithms for other tasks, like finding shortest paths, etc.


  @doc """
  Executes a DFS for a goal node from a specific "source" node

  Returns a boolean value indicating whether or not the goal is reachable from 
  the starting node

  Raises an error if the source node does not exist in the graph

  Call as follows: dfs_source?(graph, sourceNodeID, goalNodeID)
  """
  def dfs_source?(graph = %Graph{}, sourceNodeID, goalNodeID) do
    if not Graph.has_node?(graph, sourceNodeID) do
      raise(ArgumentError, "Second argument, sourceNodeID, must be a node id in graph.nodes.")
    end

    #maintain both a visited set to actually perform the algorithm,
    #and a list that records the (reverse) order in which nodes are visited
    #the *list* is currently unused, but will be utilized in the future
    {foundGoal, _visited} = dfs_source_visit(graph, sourceNodeID, goalNodeID, [set: MapSet.new, list: []])
    foundGoal
  end

  # returns {true, visited} if goal is found, else visits source node
  # and its unvisited descendants, and returns {false, visited}
  defp dfs_source_visit(g = %Graph{}, source, goal, visited) do
    #append node to the front of the visited list for efficiency
    #note that when the list is ultimately returned, it must be
    #reversed to get the original order
    visited = [set: MapSet.put(visited[:set], source),
               list: [source | visited[:list]]]

    if source == goal do
      #base case: goal found
      {true, visited} 
    else
      adj_list = Graph.get_node(g, source).adjacent |> Enum.to_list()
      dfs_source_explore_adj(g, adj_list, goal, visited) 
    end
  end

  # returns 2-tuple of form {foundGoal, visited}
  defp dfs_source_explore_adj(g = %Graph{}, [node | adj_list], goal, visited) do
    if not MapSet.member?(visited[:set], node) do   
      case dfs_source_visit(g, node, goal, visited) do
        {_foundGoal = true, visited} ->
          {true, visited}
        {_, visited} ->
          dfs_source_explore_adj(g, adj_list, goal, visited)
      end
    else
      dfs_source_explore_adj(g, adj_list, goal, visited)
    end
  end

  # base case: return {false, visited} to indicate goal not found yet after exploring 
  # the node's adjacency list, and provide the current search state (visited set)
  defp dfs_source_explore_adj(_g = %Graph{}, [], _goal, visited), do: {false, visited}

  @doc """
  Runs DFS on the entire graph (as opposed to just from a specific starting node), 
  visiting nodes in postorder while applying a state transition function. 
  Returns the state once every node in the graph has been visited.

  Call dfs_post_order/3 like so: 
  dfs_post_order(graph, visitFunc, state)

  Takes parameters "state" and an anonymous state transition function "visitFunc",
  which together are used to update the state as follows every time a node is visited:

  state = visitFunc.(state, node)

  The "state" argument passed to dfs_post_order/3 is some arbitrary initial state, 
  with the value depending on the particular application of dfs_post_order/3.

  To illustrate, toplogical_sort utilizes dfs_post_order/3 like so:
  top_sort = dfs_post_order(some_dag, &track_reverse_post_order/2, []).

  The initial state is an empty list. track_reverse_post_order is captured and 
  passed as the visitFunc, which takes inputs of the current list (i.e. the "state") 
  and current node being visited.

  Every time a node is visited, the following line is effectively executed:
  traversal_list = track_reverse_post_order.(traversal_list, node)

  track_reverse_post_order/2 prepends "node" to the front of traversal_list state, 
  and returns the new list.

  For a DAG, the reverse ordering of a postorder DFS traversal represents a valid 
  topological sort of the graph, so topological_sort can in turn just return the list 
  produced by this call to dfs_post_order/3. 
  """
  def dfs_post_order(graph = %Graph{}, visitFunc, state) do
    {state, _} = dfs_post_order(graph, visitFunc, state, MapSet.new)
    state
  end

  defp dfs_post_order(g = %Graph{nodes: nodes}, visitFunc, state, visited) do
    nodeIDs = Map.keys(nodes)

    Enum.reduce(nodeIDs, {state, visited}, fn (node, {state, visited}) ->
      if not MapSet.member?(visited, node) do
        dfs_post_order_visit(g, node, visitFunc, state, visited)
      else
        {state, visited}
      end
    end)    
   
  end

  defp dfs_post_order_visit(g = %Graph{}, node, visitFunc, state, visited) do
    
    visited = MapSet.put(visited, node)
    
    adj_list = Graph.get_node(g, node).adjacent |> Enum.to_list()

    {state, visited} = dfs_post_order_explore_adj(g, adj_list, visitFunc, state, visited)
    
    #now visit the node
    state = visitFunc.(state, node)
    {state, visited}
  end  

  defp dfs_post_order_explore_adj(g = %Graph{}, [node | adj_list], visitFunc, state, visited) do
    {state, visited} = if not MapSet.member?(visited, node) do
      dfs_post_order_visit(g, node, visitFunc, state, visited)
    else
      {state, visited}
    end
    
    dfs_post_order_explore_adj(g, adj_list, visitFunc, state, visited)
  end

  defp dfs_post_order_explore_adj(_g = %Graph{}, [], _visitFunc, state, visited), do: {state, visited}


  @doc """
  Performs a BFS search for a particular node, starting from a "source" node.

  Requires that a node with the given source id exists in the graph,
  otherwise, an ArgumentError is raised

  Invoke bfs_source(graph, sourceNodeID, goalNodeID) to execute a BFS that 
  begins at the source node and searches for the goal node, and returns a boolean
  value indicating whether or not the goal is reachable from the source.

  Optionally, provide a report_dist: true option for the last parameter,
  e.g. bfs_source(graph, source, goal, report_dist: true). 
  When report_dist: true and goal is reachable, bfs_source returns 
  a 2-tuple of the format {true, numEdges}, where numEdges is the number of 
  edges in the shortest path (in the *unweighted* sense) from the source to the goal.
  If the goal is not reachable, bfs_source always returns false on valid inputs.
  """
  # note that, as opposed to DFS, BFS is generally only used in the context of
  # searching for a goal from a particular starting node, which is why only a "source"
  # variant of BFS is implemented 
  def bfs_source(graph = %Graph{}, sourceNodeID, goalNodeID, opts \\ []) do

    reportDist = opts[:report_dist]
    cond do
      not Graph.has_node?(graph, sourceNodeID) ->
        raise(ArgumentError, "Second argument, the id of the source node, must be a node id in graph.nodes.")
      sourceNodeID == goalNodeID ->
      #we need to explicitly check the source node here, because during the BFS,
      #the implementation only checks for the goal as it goes over an adjacency list
        if reportDist, do: {true, 0}, else: true
      true ->
        #initialize BFS state (queue, visited set, and map containing info about the BFS search tree),
        #and then run the search. 
        q = :queue.in(sourceNodeID, :queue.new)
        #all entries in the bfs_tree_info will follow the format below.
        #parent represents the parent node id in the BFS tree, and dist is the minimum
        #number of edges that must be traversed on a simple path from the source to that node
        bfs_tree_info = %{sourceNodeID => [parent: nil, dist: 0]}
        visited = MapSet.new |> MapSet.put(sourceNodeID)
        
        case bfs_source(graph, goalNodeID, q, bfs_tree_info, visited) do
          false ->
            false
          {true, bfs_tree_info} when reportDist ->
            {true, bfs_tree_info[goalNodeID][:dist]}
          {true, _bfs_tree_info} ->
            true
        end
            
    end

  end

  # checks if the queue is empty/gets the node at the front of the queue
  # and explores its edges.
  # returns one of the following: 1) false, if the queue becomes empty and the goal
  # is not found or 2) a tuple in the format: {true, bfs_tree_info} once the goal is found.
  # this function essentially corresponds to the body of the while loop in a
  # typical iterative implementation of BFS
  defp bfs_source(g = %Graph{}, goal, q, bfs_tree_info, visited) do
    #remove the next node from the queue
    case :queue.out(q) do
      {:empty, _} ->
        #return false, since we know the goal has not been found yet and there
        #are no more reachable/unvisited nodes.
        false
      {{_, node}, q} ->
        unvisited_adj = get_unvisited_adj_list(g, node, visited)
        #explore the adjacency list; check for goal/add unvisited nodes to the queue
        case bfs_source_explore(g, node, goal, unvisited_adj, q, bfs_tree_info, visited) do
          {true, bfs_tree_info} ->
            #the goal was found when exploring the adjacency list,
            #so return true and the BFS tree info
           {true, bfs_tree_info}
          {q, bfs_tree_info, visited} ->
            #recurse and continue the search with the next node on the top of the queue, if any
            bfs_source(g, goal, q, bfs_tree_info, visited)
        end
    end
      
  end

  # recurses through a node's adjacency list;
  # checks for goal, and while not yet found, adds any unvisited adjacent nodes to the queue.
  # returns {true, bfs_tree_info} if goal is found via this adjacency list, else returns the
  # search state as a tuple of the following form: {q, bfs_tree_info, visited}
  defp bfs_source_explore(g = %Graph{}, parent, goal, [node | adj], q, bfs_tree_info, visited) do

    #visit this node (via the BFS parent node's adj list)
    #add its BFS tree info, and add it to the queue.
    bfs_tree_info = bfs_update_tree_info_for_child(bfs_tree_info, parent, node)    
    {q, bfs_tree_info, visited} = {:queue.in(node, q), bfs_tree_info, MapSet.put(visited, node)}

    if node == goal do
      {true, bfs_tree_info}
    else
      #recurse to explore the rest of the adjacency list
      bfs_source_explore(g, parent, goal, adj, q, bfs_tree_info, visited)
    end
        
  end

  # base case: the parent node's adjacency list has been fully explored.
  # return the current BFS state to continue searching for the goal if possible. 
  defp bfs_source_explore(_g = %Graph{}, _parent, _goal, [], q, bfs_tree_info, visited) do
    {q, bfs_tree_info, visited}
  end

  # helper function to record information for nodes in the BFS tree
  defp bfs_update_tree_info_for_child(bfs_tree_info, parent, child) do
    parentDist = bfs_tree_info[parent][:dist]
    Map.put(bfs_tree_info, child, [parent: parent, dist: parentDist + 1])
  end

  # convenience for BFS graph traversal:
  # gets the set difference between a node's adjacency list and the 
  # set of visited nodes.

  # time complexity of this function is O(n), where n is the number
  # of nodes in the set.

  # in the context of BFS the worst-case time complexity
  # for this function on a node in a graph G=(V, E) is O(|V|),
  # i.e. in the case of a node which has a directed edge to every vertex in V. 

  # note that this choice does not alter the time complexity of 
  # the BFS implementation, since the this function is called exactly once, 
  # just before BFS would iterate over every node in the adjacency list anyway, 
  # which is an operation with the same complexity.
  defp get_unvisited_adj_list(g = %Graph{}, nodeID, visited) do
    Graph.get_node(g, nodeID).adjacent
    |> MapSet.difference(visited)
    |> Enum.to_list()
  end  

  @doc """
  For a directed acyclic input graph (DAG),
  returns a list of node ids representing a toplogical sort of the graph

  Returns nil if input graph is not a DAG, 
  in which case topological sorting is undefined  

  Call as follows: topological_sort(graph)

  Note that, in general, a DAG may have multiple valid topological sorts.
  topological_sort/1 returns one of them.
  If there are multiple valid sorts, there is no guarantee as to which particular 
  one is returned.
  """
  def topological_sort(g = %Graph{directed: isDirected}) do
    if isDirected and is_acyclic?(g) do
      dfs_post_order(g, &(track_reverse_post_order/2), [])
    else
      nil
    end
  end

  # visit function meant to be passed to dfs_post_order.
  # maintains list of nodes visited in reverse post-order,
  # which for a DAG will represent a topological sort of the graph
  defp track_reverse_post_order(node_list, node) do
    [node | node_list]
  end  
  
  @doc """
  Returns true i.f.f a directed graph is acyclic.
  
  Call as follows: is_acyclic?(graph)

  This function is undefined for undirected graphs.
  
  """
  def is_acyclic?(graph = %Graph{directed: true, nodes: nodes}) do
    node_id_list = Map.keys(nodes) |> Enum.to_list()
    addAncestor = fn (ancestors, node) -> MapSet.put(ancestors, node) end
    
    is_acyclic?(graph, node_id_list, addAncestor, MapSet.new, MapSet.new)
  end

  # runs a DFS on the entire graph, while checking for cycles.
  # the search_ancestors parameter is a set of node IDs representing the current node's
  # ancestors in the DFS tree, which is used to detect cycles.
  # addAncestor is a function that adds a node to the ancestor list.
  # the function is written with the addAncestor parameter since in the future I may utilize
  # one of the pre/postorder DFS implementations to implement is_acyclic? 
  defp is_acyclic?(g = %Graph{directed: true}, [node | nl], addAncestor, search_ancestors, visited)  do
    result = if not MapSet.member?(visited, node) do
      is_acyclic_visit?(g, node, addAncestor, search_ancestors, visited)
    else
      #continue searching remaining list with the exisiting ancestors/visited list
      {search_ancestors, visited}
    end

    case result do
      false ->
        #a cycle was found 
        false
      {search_ancestors, visited} ->
        #recurse and continue checking graph for cycles, starting
        #another DFS from the next unvisited node in the graph.
        is_acyclic?(g, nl, addAncestor, search_ancestors, visited)
    end
          
  end

  # base case: by this point, every node in the graph has been visited by DFS,
  # and no cycles have been found, so return true.
  defp is_acyclic?(_g = %Graph{directed: true}, [], _addAncestor, _search_ancestors, _visited), do: true  

  defp is_acyclic_visit?(g = %Graph{directed: true}, node, addAncestor, search_ancestors, visited) do

    visited = MapSet.put(visited, node)
    #visit node by adding it to the dfs search tree ancestor set    
    search_ancestors = addAncestor.(search_ancestors, node)

    adj = Graph.get_node(g, node).adjacent |> Enum.to_list()
    case is_acyclic_explore?(g, adj, addAncestor, search_ancestors, visited) do
      false ->
        false
      {search_ancestors, visited} ->        
        #after visiting node/exploring all its edges,
        #remove it from the current ancestor set, and
        #return the updated {ancestors, visited}         
        {MapSet.delete(search_ancestors, node), visited}
    end
  end

  # returns false if a cycle is found, else a tuple of the form {search_ancestors, visited}
  defp is_acyclic_explore?(g = %Graph{directed: true}, [v | adj], addAncestor, search_ancestors, visited) do  
    cond do
      not MapSet.member?(visited, v) ->
        case is_acyclic_visit?(g, v, addAncestor, search_ancestors, visited) do
          false ->
            false            
          {search_ancestors, visited} ->
            is_acyclic_explore?(g, adj, addAncestor, search_ancestors, visited)
        end
      MapSet.member?(search_ancestors, v) ->
        #there is a back edge (i.e. an edge from this node to an ancestor node
        #in this DFS tree), thus we have detected a cycle.
        false
      true ->
        #default case: recurse on the remaining portion of the adjacency list
        is_acyclic_explore?(g, adj, addAncestor, search_ancestors, visited)
    end
  end

  # base case: all nodes in the node's adjacency list have been explored and no cycle was
  # found, so return the seach state to continue checking any more unvisited parts of the graph.
  defp is_acyclic_explore?(_g = %Graph{}, [], _addAncestor, search_ancestors, visited) do
    {search_ancestors, visited}
  end  
      
end
