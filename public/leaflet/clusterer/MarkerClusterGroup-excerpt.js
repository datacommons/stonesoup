// @license magnet:?xt=urn:btih:d3d9a9a6595521f9666a5e94cc830dab83b65699&dn=expat.txt Expat

// based on L.MarkerClusterGroup._defaultIconCreateFunction
function cluster_icon_create (cluster_count) {
    var c = ' marker-cluster-';
    if (cluster_count < 10) {
	c += 'small';
    } else if (cluster_count < 100) {
	c += 'medium';
    } else if (cluster_count < 200) {
	c += 'large';
    }
    else if (cluster_count < 700) {
        c += 'huge';
    } else {
        c += 'giant';
    }
    return new L.DivIcon({ html: '<div><span>' + cluster_count +
			   '</span></div>',
			   className: 'marker-cluster' + c,
			   iconSize: new L.Point(40, 40) });
}
// @license-end
