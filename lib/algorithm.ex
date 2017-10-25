defmodule Graph.Algorithm do

  @doc """
  Executes a DFS for a node with goalNodeID from a specific starting node.
  if found, returns goalNodeID, else nil
  """
  def dfs_source?(graph = %Graph{}, sourceNodeID, goalNodeID) do
    if not Graph.has_node?(graph, sourceNodeID) do
      raise(ArgumentError, "Second argument, sourceNodeID, must be a node id in graph.nodes.")
    end

    {foundGoal, visited} = dfs_source_visit(graph, sourceNodeID, goalNodeID, [set: MapSet.new, list: []])
    IO.inspect Enum.reverse(visited[:list])
    foundGoal
  end

  #
  defp dfs_source_visit(g = %Graph{}, source, goal, visited) do
    visited = [set: MapSet.put(visited[:set], source),
               list: [source | visited[:list]]]

    #base case: node with goal id is found
    if source == goal do
      {true, visited}
    else
      #recurse and explore every unvisited edge in this node's adjacency list.
      unvisited_adj_list = get_unvisited_adj_list(g, source, visited[:set])
      dfs_source_explore_adj(g, unvisited_adj_list, goal, visited) 
    end
  end

  defp dfs_source_explore_adj(g = %Graph{}, [node | adj_list], goal, visited) do
    if not MapSet.member?(visited[:set], node) do   
      case dfs_source_visit(g, node, goal, visited) do
        {_foundGoal = true, _} ->
          {true, visited}
        {_, visited} ->
          dfs_source_explore_adj(g, adj_list, goal, visited)
      end
    else
      dfs_source_explore_adj(g, adj_list, goal, visited)
    end
  end

  defp dfs_source_explore_adj(_g = %Graph{}, [], _goal, visited), do: {false, visited}


  @doc """

  Runs DFS on the entire graph, not just from a particular starting node.

  Supports a visit function visitFunc(state, input), which returns an updated state
  every time a node is visited.

  """
  def dfs_post_order(graph = %Graph{}, visitFunc, state) do
    dfs_post_order(graph, visitFunc, state, MapSet.new)
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

  #
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


  # Convenience for graph traversal:
  # Gets the set difference between a node's adjacency list and the 
  # set of visited nodes.

  # Time complexity of this function is O(n), where n is the number
  # of nodes in the set.

  # In the context of any of the DFS functions, the
  # worst-case time complexity for this function on a node in
  # a graph G=(V, E) is O(|V|), i.e. in the case of a node
  # which has a directed edge to every vertex in V. 

  # Note that this choice does not alter the time complexity of 
  # the DFS implementations, since the this function is called exactly once, 
  # just before DFS would iterate over every node in the adjacency list anyway, 
  # which is an operation with the same complexity.

  defp get_unvisited_adj_list(g = %Graph{}, nodeID, visited) do
    Graph.get_node(g, nodeID).adjacent
    |> MapSet.difference(visited)
    |> Enum.to_list()
  end

  # Visit function passed to post order DFS.
  # Maintains list of nodes visited in reverse post-order (which for a DAG will represent a topological sort)
  defp track_reverse_post_order(node_list, node) do
    [node | node_list]
  end

  @doc """
  Returns a list of node ids representing a toplogical sort of the graph.

  Returns nil if input graph is not a DAG, 
  in which case topological sorting is undefined.

  """
  def topological_sort(g = %Graph{directed: isDirected}) do
    if isDirected and is_acyclic?(g) do
      {traversal_order, _} = dfs_post_order(g, &(track_reverse_post_order/2), [])
      traversal_order
    else
      nil
    end
  end
  
  @doc """
  Returns true i.f.f. a directed graph is acyclic.

  """
  def is_acyclic?(graph = %Graph{directed: true, nodes: nodes}) do
    node_id_list = Map.keys(nodes) |> Enum.to_list()
    addAncestor = fn (ancestors, node) -> MapSet.put(ancestors, node) end
    
    is_acyclic?(graph, node_id_list, addAncestor, MapSet.new, MapSet.new)
  end

  defp is_acyclic?(g = %Graph{directed: true}, [node | nl], addAncestor, search_ancestors, visited)  do
    result = if not MapSet.member?(visited, node) do
      is_acyclic_visit?(g, node, addAncestor, search_ancestors, visited)
    else
      #continue searching remaining list with the exisiting ancestors/visited list
      {search_ancestors, visited}
    end

    case result do
      false ->
        false
      {search_ancestors, visited} ->
        #recurse and continue checking graph for cycles,
        #starting from next source node in the list of graph nodes
        is_acyclic?(g, nl, addAncestor, search_ancestors, visited)
    end
          
  end

  defp is_acyclic?(_g = %Graph{directed: true}, [], _addAncestor, _search_ancestors, _visited), do: true  

  defp is_acyclic_visit?(g = %Graph{}, node, addAncestor, search_ancestors, visited) do

    #visit node, adding  to dfs search tree ancestor set
    visited = MapSet.put(visited, node)    
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
  
  defp is_acyclic_explore?(g = %Graph{}, [v | adj], addAncestor, search_ancestors, visited) do  
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
        is_acyclic_explore?(g, adj, addAncestor, search_ancestors, visited)
    end
  end

  defp is_acyclic_explore?(_g = %Graph{}, [], _addAncestor, search_ancestors, visited) do
    {search_ancestors, visited}
  end  
  

  @doc """
  Executes a BFS search for a particular node from a source node.
  """
  def bfs_source(graph = %Graph{}, sourceNodeID, goalNodeID, opts \\ []) do

    reportDist = opts[:report_dist]
    cond do
      not Graph.has_node?(graph, sourceNodeID) ->
        raise(ArgumentError, "Second argument, sourceNodeID, must be a node id in graph.nodes.")
      sourceNodeID == goalNodeID ->
        if reportDist, do: {true, 0}, else: true
      true ->
        #initialize BFS state (queue and visited set), and then run the search. 
        q = :queue.in(sourceNodeID, :queue.new)
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

  defp bfs_source(g = %Graph{}, goal, q, bfs_tree_info, visited) do    
    case :queue.out(q) do
      {:empty, _} ->
        false
      {{_, node}, q} ->
        unvisited_adj = get_unvisited_adj_list(g, node, visited)
        case bfs_source(g, node, goal, unvisited_adj, q, bfs_tree_info, visited) do
          {true, bfs_tree_info} ->
           {true, bfs_tree_info}
          {q, bfs_tree_info, visited} ->
            bfs_source(g, goal, q, bfs_tree_info, visited)
        end
    end
      
  end

  #checks if goal is found or adds adjacent/child nodes to the queue
  defp bfs_source(g = %Graph{}, parent, goal, [node | adj], q, bfs_tree_info, visited) do

    #visit this node (from the BFS parent node's adj list)
    #add its BFS tree info, and add it to the queue.
    bfs_tree_info = bfs_update_tree_info_for_child(bfs_tree_info, parent, node)
    
    {q, bfs_tree_info, visited} = {:queue.in(node, q), bfs_tree_info, MapSet.put(visited, node)}

    if node == goal do
      {true, bfs_tree_info}
    else
      bfs_source(g, parent, goal, adj, q, bfs_tree_info, visited)
    end
        
  end


  defp bfs_source(_g = %Graph{}, _parent, _goal, [], q, bfs_tree_info, visited) do
    {q, bfs_tree_info, visited}
  end

  defp bfs_update_tree_info_for_child(bfs_tree_info, parent, child) do
    parentDist = bfs_tree_info[parent][:dist]
    Map.put(bfs_tree_info, child, [parent: parent, dist: parentDist + 1])
  end  
  
end
