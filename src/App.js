import './App.css';
import data from "./data";
import * as d3 from 'd3';
import { Component } from 'react';

// Uses the d3.js integration described in https://www.pluralsight.com/guides/using-d3.js-inside-a-react-app
class Grid extends Component {
  componentDidMount() {
    this.createGrid()
  }
  componentDidUpdate() {
    this.createGrid()
  }
  createGrid = () => {
    const g2a = (d) => {
      return this.props.facts.g2a[d.x + "," + d.y];
    }

    const color = d3.scaleOrdinal().domain(Object.keys(this.props.facts.shapes)).range(d3.schemeSet3);

    const node = this.node;
    const boxsize = 80;
    d3.select(node).selectAll("rect")
      .data(this.props.facts.g_node)
      .join("rect")
      .attr("x", (g) => g.x * boxsize + (g.y % 2 === 0 ? boxsize/2 : 0) + 10)
      .attr("y", (g) => g.y * boxsize + 10)
      .style("fill", (g) => {
        const a = g2a(g);
        const s = this.props.facts.color[a.x + "," + a.y];
        if (s === undefined) {
          return 'white';
        } else {
          if (this.props.facts.readout[a.x + "," + a.y] !== undefined) {
            return d3.color(color(s)).darker(0.5);
          } else {
            return color(s);
          }
        }
      })
      .attr("width", boxsize)
      .attr("height", boxsize);

    d3.select(node).selectAll("text")
      .data(this.props.facts.g_node)
      .join("text")
      .attr("x", (g) => g.x * boxsize + (g.y % 2 === 0 ? boxsize/2 : 0) + 10 + boxsize/2)
      .attr("y", (g) => g.y * boxsize + 10 + boxsize/2)
      .text((g) => {
        const c = this.props.facts.g_letter[g.x + "," + g.y];
        if (c === undefined) {
          return "";
        } else {
          return c;
        }
      });
  }
  render() {
    return <svg ref={node => this.node = node} width={800} height={700} />
  }
}

class GridForm extends Component {
  // index helps us look at multiple solutions
  constructor(props) {
    super(props);
    this.state = {'index': 0};
  }

  handleIndexChange = (e) => {
    this.setState({'index': parseInt(e.target.value)});
  }

  render() {
    // Not really sure if you can ever have multiple Calls
    const witnesses = data["Call"][0]["Witnesses"];
    const values = witnesses[this.state.index]["Value"];
    const facts = {
      g_node: [],
      g2a: {},
      place: {},
      shapes: {},
      color: {},
      readout: {},
      g_letter: {},
    };
    const env = {
      'g_node': (g) => facts.g_node.push(g),
      'g2a': (g, a) => {facts.g2a[g.x + "," + g.y] = a},
      'g': (x, y) => ({type: 'g', x: x, y: y}),
      'a': (x, y) => ({type: 'a', x: x, y: y}),
      'a_node': () => {},
      'shape': () => {},
      'shapes': (s, a) => {
        if (facts.shapes[s] === undefined) {
          facts.shapes[s] = [a];
        } else {
          facts.shapes[s].push(a);
        }
      },
      'color': (a, s) => facts.color[a.x + "," + a.y] = s,
      'readout': (a, s) => facts.readout[a.x + "," + a.y] = s,
      'place': (s, a) => facts.place[s] = a,
      'a_letter': () => {},
      'g_letter': (g, c) => facts.g_letter[g.x + "," + g.y] = c,
      'answer': () => {},
    };
    // I ended up doing parsing in this goofy way: ASP atoms look
    // like valid JavaScript programs, so what I do is I just
    // assign interpretations to these programs by giving JavaScript
    // functions for each literal, and then just "eval" the program.
    // Pretty grungy, but saves me from having to actually have a
    // parser.
    function parse_value(x) {
      // eslint-disable-next-line no-new-func
      return Function('env', 'with(env) { ' + x + '; }')(env);
    }
    values.forEach(parse_value)

    return <div>
      <div>
        Model:
        <input type="text" value={this.state.index} onChange={this.handleIndexChange} size={Math.ceil(Math.log10(witnesses.length))} />
        <input type="range" min={0} max={witnesses.length-1} value={this.state.index} onChange={this.handleIndexChange} />
      </div>
      <Grid facts={facts} index={this.state.index} />
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  }
}

function App() {
  return (
    <GridForm />
  );
}

export default App;
