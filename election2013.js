// Generated by CoffeeScript 1.6.3
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $(function() {
    var map, normalizePoste, padDigits, processRow, results, toPolygonId;
    L.TopoJSON = L.GeoJSON.extend({
      addData: function(jsonData) {
        var k, v, _ref, _results;
        if (jsonData.type === "Topology") {
          _ref = jsonData.objects;
          _results = [];
          for (k in _ref) {
            v = _ref[k];
            _results.push(L.GeoJSON.prototype.addData.call(this, topojson.feature(jsonData, v)));
          }
          return _results;
        } else {
          return L.GeoJSON.prototype.addData.call(this, jsonData);
        }
      }
    });
    map = L.map('map', {
      attributionControl: false
    }).setView([45.56, -73.7], 11);
    L.tileLayer('http://{s}.tile.cloudmade.com/{key}/65636/256/{z}/{x}/{y}.png', {
      key: "09bd425f79134130bcc6e1763e8c462f",
      minZoom: 11
    }).addTo(map);
    normalizePoste = function(p) {
      if (__indexOf.call(p, ",") < 0) {
        p += ",00";
      }
      if (p.split(",")[1].length === 1) {
        p += "0";
      }
      return p;
    };
    padDigits = function(n, d) {
      return Array(Math.max(d - ("" + n).length + 1, 0)).join(0) + n;
    };
    toPolygonId = function(d, b) {
      return padDigits(d, 3) + "-" + padDigits(b, 3);
    };
    results = {};
    processRow = function(r) {
      var id, k, p, v, _base, _results;
      p = normalizePoste(r.Poste);
      if (results[p] == null) {
        results[p] = {};
      }
      _results = [];
      for (k in r) {
        v = r[k];
        if (!(isFinite(k) && isFinite(v) && +v > 0)) {
          continue;
        }
        id = toPolygonId(r.District, k);
        if ((_base = results[p])[id] == null) {
          _base[id] = {
            winner: {
              name: "",
              votes: 0
            },
            totalVotes: 0,
            district: r.District,
            section: k,
            results: {}
          };
        }
        results[p][id].results[r.Candidat] = +v;
        results[p][id].totalVotes += +v;
        if (+v > results[p][id].winner.votes) {
          results[p][id].winner.name = r.Candidat;
          _results.push(results[p][id].winner.votes = +v);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
    return queue().defer(d3.json, "index.json").defer(d3.json, "sections.topojson").defer(d3.csv, "data.csv", processRow).await(function(error, index, sections) {
      var arrondissement, borough, colorForCandidate, k, layer, nom, opacity, optGroup, p, path, postToUse, sectionToPost, select, showResults, type, updateMap, _ref, _ref1, _ref2;
      console.dir(index);
      sectionToPost = {
        MC: {},
        CV: {}
      };
      _ref = index.posts;
      for (p in _ref) {
        type = _ref[p].type;
        if (type === "MC" || type === "CV") {
          for (k in results[p]) {
            sectionToPost[type][k] = p;
          }
        }
      }
      colorForCandidate = function(winner) {
        return index.parties["" + index.candidates[winner]].color;
      };
      showResults = function(r) {
        var arc, candidate, dim, g, pie, pieData, sorted, svg, table, v, votes, _i, _len, _ref1, _ref2;
        $("#result").append($("<p align='center'>").css({
          "margin-top": "5px"
        }).text(index.districts[r.district] + " #" + r.section));
        pieData = [];
        _ref1 = r.results;
        for (candidate in _ref1) {
          votes = _ref1[candidate];
          pieData.push({
            candidate: candidate,
            votes: votes,
            color: colorForCandidate(candidate)
          });
        }
        dim = 150;
        arc = d3.svg.arc().outerRadius(dim / 2 - 10).innerRadius(0);
        pie = d3.layout.pie().value(function(d) {
          return d.votes;
        });
        svg = d3.select($("#result").get(0)).append("svg").attr("width", 250).attr("height", dim).append("g").attr("transform", "translate(" + 125 + "," + dim / 2 + ")");
        g = svg.selectAll(".arc").data(pie(pieData)).enter().append("g").attr("class", "arc");
        g.append("path").attr("d", arc).style("fill", function(d) {
          return d.data.color;
        }).style("stroke", "white").style("weight", 1);
        table = $("<table cellpadding='5' width='100%'>").append($("<tr>").append($("<th colspan='2'>").text("Candidat"), $("<th>").css({
          width: "20px"
        }).text("Votes")));
        sorted = ((function() {
          var _ref2, _results;
          _ref2 = r.results;
          _results = [];
          for (k in _ref2) {
            v = _ref2[k];
            _results.push([k, v]);
          }
          return _results;
        })()).sort(function(a, b) {
          return b[1] - a[1];
        });
        for (_i = 0, _len = sorted.length; _i < _len; _i++) {
          _ref2 = sorted[_i], candidate = _ref2[0], votes = _ref2[1];
          table.append($("<tr>").append($("<td>").css({
            width: "15px",
            background: colorForCandidate(candidate)
          }), $("<td>").text(candidate), $("<td align='right'>").html(votes + "&nbsp;")));
        }
        return $("#result").append(table);
      };
      opacity = d3.scale.linear().range([0, 0.7]).domain([0, 5]).clamp(true);
      path = d3.geo.path().projection(d3.geo.mercator().scale(60000));
      postToUse = function(post, d) {
        if (post === "CV" || post === "MC") {
          return sectionToPost[post][d.properties.id];
        } else {
          return post;
        }
      };
      layer = null;
      updateMap = function(postIn) {
        if (layer != null) {
          map.removeLayer(layer);
        }
        layer = new L.TopoJSON(sections, {
          style: function(d) {
            var c, o, post, style, totalVotes, winner;
            post = postToUse(postIn, d);
            if (d.properties.id in results[post]) {
              winner = results[post][d.properties.id].winner.name;
              c = colorForCandidate(winner);
              totalVotes = results[post][d.properties.id].totalVotes;
              o = opacity(totalVotes / path.area(d));
            } else {
              c = "white";
              o = 0.5;
            }
            style = {
              fillColor: c,
              color: c,
              weight: 1,
              fillOpacity: o
            };
            return style;
          },
          filter: function(d) {
            var post;
            post = postToUse(postIn, d);
            if (post == null) {
              return false;
            }
            return d.properties.id in results[post];
          },
          onEachFeature: function(f, l) {
            return l.on({
              dblclick: function(e) {
                return map.setView(e.latLng, map.getZoom() + 1);
              },
              mouseout: function(e) {
                layer.resetStyle(e.target);
                return $("#result").html("");
              },
              mouseover: function(e) {
                var post;
                e.target.setStyle({
                  weight: 4,
                  color: '#fff',
                  opacity: 1,
                  fillOpacity: 0.9
                });
                if (!L.Browser.ie && !L.Browser.opera) {
                  e.target.bringToFront();
                }
                post = postToUse(postIn, e.target.feature);
                return showResults(results[post][e.target.feature.properties.id]);
              }
            });
          }
        });
        return map.addLayer(layer);
      };
      updateMap("0,00");
      select = $("<select>").css({
        width: "240px"
      });
      optGroup = $("<optgroup>").attr("label", "Montréal");
      optGroup.append($("<option>").val("0,00").text("Mairie de Montréal"));
      optGroup.append($("<option>").val("MC").text("Mairies d'arrondissement"));
      optGroup.append($("<option>").val("CV").text("Conseil de Ville"));
      _ref1 = index.posts;
      for (k in _ref1) {
        _ref2 = _ref1[k], arrondissement = _ref2.arrondissement, nom = _ref2.nom;
        if (borough !== arrondissement) {
          borough = arrondissement;
          select.append(optGroup);
          optGroup = $("<optgroup>").attr("label", index.boroughs[borough]);
        }
        nom = nom.replace("Maire de l'arrondissement", "Mairie").replace("Conseiller de la ville arrondissement", "CV").replace("Conseiller de la ville - District électoral", "CV").replace("Conseiller d'arrondissement - District électoral", "CA");
        optGroup.append($("<option>").val(k).text(nom));
      }
      select.append(optGroup);
      select.bind("change", function(e) {
        e.preventDefault();
        updateMap($(this).val());
        e.stopPropagation();
        return false;
      });
      $("#sidebar").append(select).append($("<div id='result'>"));
      return $("select").chosen({
        search_contains: true
      });
    });
  });

}).call(this);
