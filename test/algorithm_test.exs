defmodule AlgorithmTest do
  use ExUnit.Case
  doctest Graph.Algorithm

  import Graph.Algorithm  
  alias Graph.Node


  @moduledoc """
  AlgorithmTest contains unit and integration tests for Graph.Algorithm.

  TODO:
  *add more tests for directed graphs
  *add unit tests for dfs_post_order* functions
  *add some tests for more complex graphs where appropriate

  """

  #~~~TEST HELPER FUNCTIONS~~~
  #These functions are used in tests to make sample
  #input graphs of various types.

  #creates a list of num nodes with binary ids  "0"..."<num - 1>"
  def create_nodes(num) when num >= 0 do
    Enum.map(0..(num - 1), fn i -> Node.new(to_string i) end)
  end

  #This example is from page 596 of "Introduction to Algorithms",
  #3rd edition, by Cormen et al.  
  def sample_connected_graph() do
    g = Graph.new(MapSet.new(create_nodes(8)))
    
    import Graph
    add_edge(g, "0", "4")
    |> add_edge("0", "1")
    |> add_edge("1", "5")
    |> add_edge("2", "5")
    |> add_edge("2", "6")
    |> add_edge("2", "3")
    |> add_edge("3", "6")
    |> add_edge("3", "7")
    |> add_edge("5", "6")
    |> add_edge("6", "7")
            
  end

  #Creates the sample_connected_graph but with an additional
  #isolated node.
  #Returns {graph, unreachableID}
  def sample_disconnected_graph() do
    g = sample_connected_graph()

    unreachableNode = Node.new(to_string(Graph.num_nodes(g)))
    g = Graph.add_node(g, unreachableNode)    

    {g, unreachableNode.id}
  end

  def sample_simple_acyclic() do
    g = Graph.new(MapSet.new(create_nodes(4)))
    g = %Graph{g | directed: true}

    import Graph
    
    add_edge(g, "0", "1")
    |> add_edge("1", "2")
    |> add_edge("2", "3")  
  end

  def sample_simple_cyclic() do
    import Graph
    
    sample_simple_acyclic()
    |> add_edge("3", "0")        
  end
  
  #Creates a sample_dag to test toplogical sorting
  #This example is from page 613 of "Introduction to Algorithms",
  #3rd edition, by Cormen et al.
  def sample_dag() do
    nl = [
      Node.new("undershorts"),
      Node.new("pants"),
      Node.new("belt"),
      Node.new("shirt"),
      Node.new("tie"),
      Node.new("jacket"),
      Node.new("socks"),
      Node.new("shoes"),
      Node.new("watch")
    ]
    
    nodeset = MapSet.new(nl)
    g = Graph.new(nodeset)
    g = %Graph{g | directed: true}

    import Graph
    add_edge(g, "undershorts", "pants")
    |> add_edge("undershorts", "shoes")
    |> add_edge("pants", "belt")
    |> add_edge("pants", "shoes")
    |> add_edge("belt", "jacket")
    |> add_edge("shirt", "belt")    
    |> add_edge("shirt", "tie")
    |> add_edge("tie", "jacket")
    |> add_edge("socks", "shoes")    
    
  end

  #~~~TESTS~~~
  
  @tag :dfs_source?
  test "dfs_source? tests" do
    
    IO.puts "Testing dfs_source? on undirected graph inputs...\n"

    g = sample_connected_graph()

    IO.puts "Testing dfs_source? on reachable goals..."
    assert Graph.Algorithm.dfs_source?(g, "1", "3")
    IO.puts "Success.\n"

    IO.puts "Testing dfs_source? on unreachable goals..."
    {g, unreachableNodeID} = sample_disconnected_graph()
    assert not Graph.Algorithm.dfs_source?(g, "1", unreachableNodeID)
    IO.puts "Success.\n"
    
  end

  @tag :bfs_source
  test "bfs_source tests" do
    
    IO.puts("Testing bfs_source on undirected graph inputs...\n")
    
    g = sample_connected_graph()
    
    IO.puts "Testing bfs_source on a reachable node, returning shortest path dist..."
    assert bfs_source(g, "4", "3", report_dist: true) == {true, 5}
    IO.puts "Success.\n" 

    IO.puts "Testing bfs_source on a reachable node, without returning shortest path dist..."
    assert bfs_source(g, "4", "3") == true 
    IO.puts "Success.\n"
    
    IO.write "Testing bfs_source on a reachable node, "
    IO.puts "where the goal is the starting node, without returning dist..."
    assert bfs_source(g, "4", "4") == true
    IO.puts "Success.\n"

    IO.write "Testing bfs_source on a reachable node, "
    IO.puts "where the goal is the starting node, and returning dist..."
    assert bfs_source(g, "4", "4", report_dist: true) == {true, 0}
    IO.puts "Success.\n"    
    
    IO.puts "Testing bfs_source on a unreachable node..."
    {g, unreachableID} = sample_disconnected_graph()
    assert not bfs_source(g, "4", unreachableID)
    IO.puts "Success.\n"

    IO.write "Testing that bfs_source on a unreachable node "
    IO.puts "only returns false even when given report_dist: true option..."
    {g, unreachableID} = sample_disconnected_graph()
    assert not bfs_source(g, "4", unreachableID, report_dist: true)
    IO.puts "Success.\n" 
    
  end

  @tag :is_acyclic?
  test "is_acyclic" do
    IO.puts "Testing various cases for is_acyclic?...\n"
    
    g = sample_simple_acyclic()
        
    IO.puts "Testing if acyclic graph is acyclic..."
    assert is_acyclic?(g)
    IO.puts "Success.\n"

    IO.puts "Testing if cyclic graph is acyclic..."
    g = sample_simple_cyclic()
    assert not is_acyclic?(g)
    IO.puts "Success.\n"
    
  end

  @tag :topological_sort
  #Note that all of the dfs_post_order* functions are tested here,
  #since topological_sort relies on them. Per the TODO list, 
  #unit tests for dfs_post_order* will be added in the future.

  test "topological_sort tests" do

    IO.puts "Testing topological_sort for various input cases...\n"

    IO.puts "Testing topological_sort on a DAG..."
    g = sample_dag()
    #Note: since typically there are multiple topological sortings for a given DAG,
    #the initial output was first generated by running topological_sort on the sample graph
    #and then verified by hand to be valid.

    #Though topological_sort relies on the state of Map and MapSet data structures in the graph,
    #which in general do not guarantee any particular ordering of the values they contain,
    #for small enough sizes, those data structures do actually follow a deterministic ordering,
    #and so this input for topological_sort should always evaluate to the list literal below.
    
    ts = ["watch", "undershorts", "socks", "shirt", "tie", "pants", "shoes", "belt", "jacket"]
    ts_generated = topological_sort(g)
    assert ts == ts_generated
    IO.inspect ts_generated
    IO.puts "Success.\n"    


    IO.puts "Testing topological_sort returns nil for an undirected graph..."
    g = sample_connected_graph()
    assert topological_sort(g) == nil
    IO.puts "Success.\n"

    IO.puts "Testing topological_sort returns nil for a cyclic graph..."
    g = sample_simple_cyclic()
    assert topological_sort(g) == nil    
    IO.puts "Success.\n"
    
  end
  
end
