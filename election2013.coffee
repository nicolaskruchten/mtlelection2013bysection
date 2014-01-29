$ ->
    L.TopoJSON = L.GeoJSON.extend
        addData: (jsonData) ->
            if (jsonData.type == "Topology")
                for k, v of jsonData.objects
                    L.GeoJSON.prototype.addData.call(this, topojson.feature(jsonData, v))
            else 
                L.GeoJSON.prototype.addData.call(this, jsonData)
        
    map = L.map('map', attributionControl: false).setView([45.56, -73.7], 11)
    L.tileLayer('http://{s}.tile.cloudmade.com/{key}/65636/256/{z}/{x}/{y}.png', {
        key: "09bd425f79134130bcc6e1763e8c462f",
        minZoom: 11,
    }).addTo(map)


    normalizePoste = (p) -> 
        p += ",00" if "," not in p
        p += "0" if p.split(",")[1].length == 1
        return p

    padDigits = (n, d) -> Array(Math.max(d - "#{n}".length + 1, 0)).join(0) + n

    toPolygonId = (d, b) -> padDigits(d,3)+"-"+padDigits(b,3)

    results = {}
    processRow = (r) ->
        p = normalizePoste r.Poste
        results[p] ?= {}
        for k,v of r when isFinite(k) and isFinite(v) and +v > 0
            id = toPolygonId r.District, k
            results[p][id] ?= 
                winner: {name: "", votes: 0}
                totalVotes: 0 
                district: r.District 
                section: k
                results: {}
            results[p][id].results[r.Candidat] = +v
            results[p][id].totalVotes += +v
            if +v > results[p][id].winner.votes
                results[p][id].winner.name = r.Candidat
                results[p][id].winner.votes = +v

    queue()
        .defer(d3.json, "index.json")
        .defer(d3.json, "sections.topojson")
        .defer(d3.csv, "data.csv", processRow)
        .await (error, index, sections) ->
            console.dir index
            sectionToPost = MC: {}, CV: {}
            for p, {type} of index.posts when type in ["MC", "CV"]
                for k of results[p]
                    sectionToPost[type][k] = p

            colorForCandidate = (winner) ->
                index.parties[""+index.candidates[winner]].color

            showResults = (r) ->


                $("#result").append $("<p align='center'>")
                    .css("margin-top": "5px")
                    .text(index.districts[r.district]+" #"+r.section)

                pieData = []
                for candidate, votes of r.results
                    pieData.push
                        candidate: candidate
                        votes: votes
                        color: colorForCandidate candidate

                dim = 150

                arc = d3.svg.arc()
                  .outerRadius(dim/2 - 10)
                  .innerRadius(0)

                pie = d3.layout.pie().value((d) -> d.votes)

                svg = d3.select($("#result").get(0)).append("svg")
                    .attr("width", 250)
                    .attr("height", dim)
                  .append("g")
                    .attr("transform", "translate(" + 125 + "," + dim / 2 + ")")


                g = svg.selectAll(".arc")
                    .data(pie(pieData))
                  .enter().append("g")
                    .attr("class", "arc")

                g.append("path")
                    .attr("d", arc)
                    .style("fill", (d) -> d.data.color )
                    .style("stroke", "white" )
                    .style("weight", 1 )

                table = $("<table cellpadding='5' width='100%'>").append(
                    $("<tr>").append(
                        $("<th colspan='2'>").text("Candidat"),
                        $("<th>").css(width: "20px").text("Votes"),
                        )
                    )
                sorted = ([k, v] for k, v of r.results).sort (a,b) -> b[1] - a[1]
                for [candidate, votes] in sorted
                    table.append $("<tr>").append(
                        $("<td>").css(
                            width: "15px", 
                            background: colorForCandidate(candidate)
                            ),
                        $("<td>").text(candidate),
                        $("<td align='right'>").html(votes+"&nbsp;"),
                        )
                $("#result").append(table)             

            opacity = d3.scale.linear().range([0,0.7]).domain([0,5]).clamp(true)
            path = d3.geo.path().projection(d3.geo.mercator().scale(60000))

            postToUse = (post, d) ->
                if post in ["CV", "MC"]
                    return sectionToPost[post][d.properties.id]
                else
                    return post

            layer = null
            updateMap = (postIn) ->
                map.removeLayer(layer) if layer?
                layer = new L.TopoJSON sections, 
                    style: (d) ->
                        post = postToUse(postIn, d)
                        if d.properties.id of results[post]
                            #console.dir results[post][d.properties.id]
                            winner = results[post][d.properties.id].winner.name
                            c= colorForCandidate(winner)
                            totalVotes = results[post][d.properties.id].totalVotes
                            o = opacity(totalVotes/path.area(d))
                        else
                            c = "white"
                            o = 0.5
                        style = 
                            fillColor: c
                            color: c
                            weight: 1
                            fillOpacity: o
                        return style
                    filter: (d) -> 
                        post = postToUse(postIn, d)
                        if not post?
                            return false
                        return d.properties.id of results[post]
                    onEachFeature: (f, l) ->
                        l.on
                            dblclick: (e) -> 
                                map.setView(e.latLng, map.getZoom()+1)
                            mouseout: (e) ->
                                layer.resetStyle(e.target)
                                $("#result").html("")
                            mouseover: (e) ->
                                e.target.setStyle
                                    weight: 4
                                    color: '#fff'
                                    opacity: 1
                                    fillOpacity: 0.9

                                if (!L.Browser.ie && !L.Browser.opera) 
                                    e.target.bringToFront()

                                post = postToUse(postIn, e.target.feature)
                                showResults results[post][e.target.feature.properties.id]

                map.addLayer(layer)

            updateMap "0,00"


            select = $("<select>").css(width: "240px")
            optGroup = $("<optgroup>").attr "label", "Montréal"
            optGroup.append $("<option>").val("0,00").text("Mairie de Montréal")
            optGroup.append $("<option>").val("MC").text("Mairies d'arrondissement")
            optGroup.append $("<option>").val("CV").text("Conseil de Ville")

            for k, {arrondissement, nom} of index.posts
                if borough != arrondissement
                    borough = arrondissement
                    select.append optGroup
                    optGroup = $("<optgroup>").attr "label", index.boroughs[borough]
                nom = nom
                    .replace("Maire de l'arrondissement", "Mairie")
                    .replace("Conseiller de la ville arrondissement", "CV")
                    .replace("Conseiller de la ville - District électoral", "CV")
                    .replace("Conseiller d'arrondissement - District électoral", "CA")
                optGroup.append $("<option>").val(k).text(nom)
            select.append optGroup
            select.bind "change", (e) -> 
                e.preventDefault()
                updateMap $(this).val()
                e.stopPropagation()
                return false
            $("#sidebar").append(select).append($("<div id='result'>"))

            $("select").chosen({search_contains: true})

