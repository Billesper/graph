defmodule GraphTest do
  use ExUnit.Case
  doctest Graph

  alias Graph.Node


  #~~~TEST HELPER FUNCTIONS~~~
  @doc """
  creates num nodes with ids in interval [0, num]
  """
  def create_nodes(num) when num >= 0 do
    Enum.map(0..num, fn i -> Node.new(to_string i) end)
  end

  @doc """
  Takes a list of nodes nl and a MapSet of ids, 
  and for any nodes in nl not in destIDSet, 
  adds an edge from that node to each node in destIDSet.

  Returns the transformed list of nodes.
  """
  def add_some_edges(nl, destIDSet) do

    #tranforms node by adding an edge from it to each node in the set
    add_edge_set = fn (node, destIDSet) ->
        Enum.reduce(destIDSet, node, fn (id, node) ->
          Node.add_adjacent(node, to_string(id))
        end)
    end

    #for each node in the list not in destSet, add edges to nodes in destIDSet
    Enum.map(nl, fn node ->
      if not MapSet.member?(destIDSet, Node.get_id(node)) do
        add_edge_set.(node, destIDSet)
      else
        node #just return original node
      end
    end)

  end

  def sample_graph() do
    #set up correct version of graph we will attempt to create below
    nodeEdges = MapSet.new(["2", "3"])
    outputGraphNodes = %{
     "0" => %Graph.Node{adjacent: nodeEdges, data: nil, id: "0"},
     "1" => %Graph.Node{adjacent: nodeEdges, data: nil, id: "1"},
     "2" => %Graph.Node{adjacent: MapSet.new, data: nil, id: "2"},
     "3" => %Graph.Node{adjacent: MapSet.new, data: nil, id: "3"},
     "4" => %Graph.Node{adjacent: nodeEdges, data: nil, id: "4"},
     "5" => %Graph.Node{adjacent: nodeEdges, data: nil, id: "5"}
    }
    
    %Graph{directed: false, nodes: outputGraphNodes, weighted: false}    
  end

  def generate_sample_graph() do

    # i) create list of nodes
    destIDs = MapSet.new() |> MapSet.put("2") |> MapSet.put("3")
    nl = create_nodes(5) |> add_some_edges(destIDs)
    # ii) create a new graph and add nodes from list 
    g = Enum.reduce nl, Graph.new, fn (node, g) ->
      Graph.add_node(g, node)
    end
    
    {g, nl}
    
  end

  #~~~TESTS~~~

  test "graph creation" do
    
    {g, _} = generate_sample_graph()
   
    IO.puts("Checking generated graph against correct graph...")
    assert g == sample_graph()
    IO.puts("Success\n")
   
    #TODO: update removed_node to remove undirected edges of a node when the graph is undirected, then write test here
  end

  test "has_node?" do
    {g, nl} = generate_sample_graph()
  
    IO.puts "Checking that has_node? returns true for all nodes added to the generated graph..."
    assert Enum.reduce nl, true, fn (node, hasNode) ->
      hasNode and Graph.has_node?(g, Node.get_id(node))
    end
    IO.puts "Success\n"

    IO.puts "Checking that has_node? returns false for some keys not in the map..."
    assert Graph.has_node?(g, "foo") == false
    assert Graph.has_node?(g, "bar") == false
    assert Graph.has_node?(g, "6") == false
    IO.puts "Success\n"
  end

  test "get_nodes, num_nodes" do
    {g, nl} = generate_sample_graph()

    #check if get_nodes returns the right nodes
    IO.write "Checking that get_nodes returns the same nodes as the "
    IO.puts "list of nodes used to create the graph..."
    assert Map.values(Graph.get_nodes(g)) == nl
    IO.puts("Success\n")    

    IO.puts "Checking that num_nodes returns the proper number of nodes in the graph..."
    assert length(nl) == Graph.num_nodes(g)
    IO.puts "Success\n"
  end

  test "add_node, remove_node, get_node" do
    {g, nl} = generate_sample_graph()
    
    IO.puts "Checking that add_node properly adds a new node to the graph..."
    newNode = %Node{id: to_string(length(nl))}
    g = Graph.add_node(g, newNode)
    assert Graph.has_node? g, Node.get_id(newNode)
    assert Graph.num_nodes(g) == (length(nl) + 1)
    IO.puts "Success\n"
    
    IO.puts "Checking that get_node properly returns the intended node from the graph..."
    assert Graph.get_node(g, newNode.id) == newNode
    IO.puts "Success\n"
    
    IO.puts "Checking that add_node does not add a node when the graph has one with the same id...\n"
    g = Graph.add_node(g, newNode)
    assert Graph.num_nodes(g) == (length(nl) + 1)
    IO.puts "\nSuccess\n"
   
    IO.puts "Checking that remove_node properly removes the node that was added after generation..."
    assert Graph.has_node?(g, newNode.id)
    g = Graph.remove_node(g, newNode.id)
    assert not Graph.has_node?(g, newNode.id)
    assert Graph.num_nodes(g) == length(nl)
    IO.puts "Success\n"
  end

  test "add_edge, remove_edge" do
    {g, _} = generate_sample_graph()
    
    IO.puts "Checking that add_edge properly adds an edge for two nodes in the exisiting undirected graph..."
   
    source = "0"
    dest = "5"
    
    has_edge? = fn(g, sourceID, destID) ->
      (Graph.get_node(g, sourceID) |> Node.has_adj_node?(destID))
    end
    
    has_uedge? = fn (g, sourceID, destID) ->
      has_edge?.(g, sourceID, destID) and has_edge?.(g, destID, sourceID)
    end 
    
    assert not has_uedge?.(g, source, dest)
    g = Graph.add_edge(g, source, dest)
    assert has_uedge?.(g, source, dest)
   
    IO.puts "Success\n"

    IO.puts "Testing removal of an undirected edge..."
    g = Graph.remove_edge(g, source, dest)
    assert not has_edge?.(g, source, dest) and not has_edge?.(g, dest, source)
    IO.puts "Success\n"    

    #change the graph to directed
    g = %Graph{g | directed: true}

    IO.puts "Testing addition of a directed edge..."
    #add the same edge, but to the directed version of the graph.
    g = Graph.add_edge(g, source, dest)
    assert has_edge?.(g, source, dest) and not has_edge?.(g, dest, source)
    IO.puts "Success\n"

    #now add directed edge from source to dest, so that that the graph
    #now has directed edges (source, dest) and (dest, source)
    g = Graph.add_edge(g, dest, source)

    IO.puts "Testing removal of a directed edge..."
    g = Graph.remove_edge(g, source, dest)
    assert not has_edge?.(g, source, dest) and has_edge?.(g, dest, source)
    IO.puts "Success\n"    
    
  end
  
end
