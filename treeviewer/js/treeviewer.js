// ************** Generate the tree diagram ***************** 
var TreeViewer = function () {
  var MARGIN      = {top: 20, right: 120, bottom: 20, left: 120};
  var WIDTH       = 1000 - MARGIN.right - MARGIN.left  ;
  var HEIGHT      = 1000  - MARGIN.top   - MARGIN.bottom; 
  var DEPTH_UNIT  = 100;
  var ARM_LENGTH  = 10;
  var NODE_RADIUS = 5;
  var EPS         = 1e-6;
  var DURATION    = 600;

  this.nodeCounter   = 0; 

  this.setup = function () {
    this.tree_layout = d3.layout.tree()
      .size([HEIGHT, WIDTH]);

    this.diagonal = d3.svg.diagonal() 
      .projection(function(d) { return [d.y, d.x]; }); 

    this.tip = d3.tip().attr('class', 'd3-tip').html(function(d) { 
      var str = '';
      if ( d.name       ) str += 'name: ' + d.name;
      else                str += 'type: ' + d.type;

      if ( d.created_at ) str += '</br>created_at: ' + d.created_at;
      if ( d.size >= 0  ) str += '</br>size: ' + d.size + ' B';
      if ( d.digest     ) str += '</br>digest: ' + d.digest;
      if ( d.content    ) str += '</br>content: ' + d.content;

      return str;
    }) 
    .direction('e')
    .offset([0, 10]);

    this.svg = d3.select("#inner").append("svg") 
      .attr("width" ,  WIDTH + MARGIN.right + MARGIN.left  )
      .attr("height", HEIGHT + MARGIN.top   + MARGIN.bottom)
      .append("g").attr("transform", "translate(" + MARGIN.left + "," + MARGIN.top + ")"); 

    this.svg.call(this.tip);
  };

  this.load_json = function (path) {
    var viewer = this;

    d3.json(path, function(json) {
      var root = {'name': null, 'digest': null, children: json}; // root is dummy node
      root.x0 = HEIGHT / 4;
      root.y0 = 0;

      root.children.forEach(function (d) {
        if ( isCommit(d) ) d.children = [d.root];
      });

      root.children//.forEach(toggleAll);

      update(viewer, root, root); 
    });

  };

  ////////////////////
  // Local Function //
  ////////////////////
  function update(viewer, root, source) { 
    // Compute the new tree layout. 
    var nodes = viewer.tree_layout.nodes(root).reverse();
    var links = viewer.tree_layout.links(nodes); 

    // Normalize for fixed-depth. 
    nodes.forEach(function(d,i) { 
      var p = nodes[i].parent;
      if ( p ) { 
        d.y = p.depth * DEPTH_UNIT; 
      } else { 
        d.y = d.depth * DEPTH_UNIT; 
      }
    }); 

    // Update the nodes…
    var node = viewer.svg.selectAll("g.node") 
      .data(nodes, function(d) { 
        return d.id || (d.id = viewer.nodeCounter++); 
      });

    // Enter any new nodes at the parent's previous position. 
    var nodeEnter = node.enter().append("g") 
      .attr("class", "node")
      .attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; }) 
      .on("click", function(d) { 
        toggle(d);
        update(viewer, root, d); 
      })
      .on("mouseover", viewer.tip.show)
      .on("mouseout" , viewer.tip.hide);

    nodeEnter.append("circle") 
      .attr("r", EPS) 
      .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; }); 

    nodeEnter.append("text")
      .attr("x", function(d) { return d.children || d._children ? -ARM_LENGTH : ARM_LENGTH; })
      .attr("dy", ".35em")
      .attr("text-anchor", function(d) { return d.children || d._children ? "end" : "start"; })
      .attr("transform", "translate(0, -10)")
      .text(function(d) { return label(d.name) || label(d.created_at); })
      .style("fill-opacity", EPS);

    // Transition nodes to their new position. 
    var nodeUpdate = node.transition()
      .duration(DURATION)
      .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; });

    nodeUpdate.select("circle")
      .attr("r", function(d) { return d.type ?  NODE_RADIUS : EPS; })
      .style("fill", function(d) { return d.type != 'blob' ? "lightsteelblue" : "#fff"; });

    nodeUpdate.select("text")
      .style("fill-opacity", 1); 

    // Transition exiting nodes to the parent's new position. 
    var nodeExit = node.exit().transition() 
      .duration(DURATION) 
      .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; }) 
      .remove(); 

    nodeExit.select("circle") 
      .attr("r", EPS);

    nodeExit.select("text") 
      .style("fill-opacity", EPS);

    // Update the links…
    var link = viewer.svg.selectAll("path.link") 
      .data(links, function(d) { return d.target.id; }); 

    // Enter any new links at the parent's previous position. 
    link.enter().insert("path", "g") 
      .attr("class", "link") 
      .attr("d", function(d) { 
        var o = {x: source.x0, y: source.y0}; 
        return viewer.diagonal({source: o, target: o}); 
      }); 

    // Transition links to their new position. 
    link.transition() 
      .duration(DURATION) 
      .attr("d", viewer.diagonal); 

    // Transition exiting nodes to the parent's new position. 
    link.exit().transition() 
      .duration(DURATION) 
      .attr("d", function(d) { 
        var o = {x: source.x, y: source.y}; 
        return viewer.diagonal({source: o, target: o}); 
      }).remove(); 

    // Stash the old positions for transition.
    nodes.forEach(function(d) { 
      d.x0 = d.x; 
      d.y0 = d.y; 
    }); 
  }

  function isCommit(d) {
    return !!(d.root);
  }

  function label(str) {
    var max_len = 16;
    if ( str && str.length > max_len ) {
      return str.slice(0, max_len) + '...';
    } else {
      return str ;
    }
  }

  // Toggle children on click. 
  function toggle(d) {
    if (d.children) { 
      d._children = d.children; 
      d.children = null; 
    } else { 
      d.children = d._children; 
      d._children = null; 
    } 
  }

  // Toggle all children
  function toggleAll(d) {
    if (d.children) {
      d.children.forEach(toggleAll);
      toggle(d);
    }
  }
} // TreeViewer

var viewer = new TreeViewer();
viewer.setup();
viewer.load_json('repo.json');

//d3.select(self.frameElement).style("height", "500px"); 
