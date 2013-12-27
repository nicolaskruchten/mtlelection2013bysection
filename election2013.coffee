$ ->
    L.TopoJSON = L.GeoJSON.extend
        addData: (jsonData) ->
            if (jsonData.type == "Topology")
                for k, v of jsonData.objects
                    L.GeoJSON.prototype.addData.call(this, topojson.feature(jsonData, v))
            else 
                L.GeoJSON.prototype.addData.call(this, jsonData)
        
    opacity = d3.scale.linear().range([0,0.7]).domain([0,5]).clamp(true)

    candidates = 
        "Bergeron": "#4daf4a"
        "Coderre":  "#e41a1c"
        "Joly":     "#377eb8"
        "Côté":     "#ff7f00"

    percentages = (votes) ->
        result = {}
        sum = 0
        for c of candidates when votes[c]?
            v = parseInt(votes[c])
            sum += v
            result[c] = v

        for k of result
            result[k] /= sum
        
        result.sum = sum
        return result


    map = L.map('map').setView([45.55, -73.7], 11)

    L.tileLayer('http://{s}.tile.cloudmade.com/{key}/65636/256/{z}/{x}/{y}.png', {
        key: "09bd425f79134130bcc6e1763e8c462f",
        minZoom: 11,
        attribution: """Base map from <a href="http://cloudmade.com" target="_blank">CloudMade</a> | Data from <a href="http://donnees.ville.montreal.qc.ca/" target="_blank">Montreal Open Data Portal</a> | &copy; <a href="http://nicolas.kruchten.com/" target="_blank">Nicolas Kruchten</a> 2013"""
    }).addTo(map)

    info = L.control()

    info.onAdd = (map) ->
        this._div = L.DomUtil.create('div', 'info')
        this.update()
        return this._div
    

    info.update = (props) ->
        if not props?
            return this._div.innerHTML = ""
        props.District = props.District.replace(/\?/g, '-')
        props.District = props.District.replace(/\d*-/, '')
        result = ""
        result += "<h4>#{props.ARRONDISSEMENT} <br /> #{props.District} ##{props.Bureau}</h4>"

        pieData = []
        for c of candidates when props[c]?
            pieData.push
                candidate: c
                votes: props[c]
                color: candidates[c]

        this._div.innerHTML = result

        dim = 250

        arc = d3.svg.arc()
          .outerRadius(dim/2 - 10)
          .innerRadius(0)

        pie = d3.layout.pie().value((d) -> d.votes)

        svg = d3.select(this._div).append("svg")
            .attr("width", dim)
            .attr("height", dim)
          .append("g")
            .attr("transform", "translate(" + dim / 2 + "," + dim / 2 + ")")


        g = svg.selectAll(".arc")
            .data(pie(pieData))
          .enter().append("g")
            .attr("class", "arc")

        g.append("path")
            .attr("d", arc)
            .style("fill", (d) -> d.data.color )

        g.append("text")
            .attr("transform", (d) -> return "translate(" + arc.centroid(d) + ")" )
            .style("text-anchor", "middle")
            .text((d) -> d.data.candidate )

        g.append("text")
            .attr("transform", (d) -> return "translate(" + arc.centroid(d) + ")" )
            .attr("dy", "1em")
            .style("text-anchor", "middle")
            .text((d) -> d.data.votes )

    
    info.addTo(map)
    path = d3.geo.path().projection(d3.geo.mercator().scale(60000))

    blended = (data) ->
        "rgb("+parseInt(255*data["Coderre"])+","+parseInt(255*data["Bergeron"])+","+parseInt(255*data["Joly"])+")";
        
    winner = (data) ->
        max =  0
        maxKey = ""
        for c of candidates when data[c]?
            if data[c] > max
                max = data[c]
                maxKey = c
        return candidates[maxKey]

    d3.json "sections.topojson", (error, data) ->
        polys = new L.TopoJSON data, 
            style: (d) ->
                data = percentages(d.properties)
                if /blended/.test window.location.href
                    c = blended(data)
                else
                    c = winner(data)

                style = 
                    fillColor: c
                    color: c
                    weight: 1
                    fillOpacity: opacity(data.sum/path.area(d))
                return style

            onEachFeature: (feature, layer) ->
                layer.on
                    mouseout: (e) ->
                        polys.resetStyle(e.target)
                        info.update()
                    mouseover: (e) ->
                        e.target.setStyle
                            weight: 4
                            color: '#fff'
                            opacity: 1
                            fillOpacity: 0.9

                        if (!L.Browser.ie && !L.Browser.opera) 
                            e.target.bringToFront()

                        info.update(e.target.feature.properties)
                
        polys.addTo(map);
