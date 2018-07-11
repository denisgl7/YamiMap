// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 28/01/2018.
//
// =================================================================================================

package maps.config {
/**
 * Based on
 * https://qms.nextgis.com/geoservices/
 *
 */
public class CommonCollection {

    // @see https://qms.nextgis.com/geoservices/1298/
    public static const GLOBAL_SURFACE_WATER_TRANSITIONS:Object = {
        template: "https://storage.googleapis.com/global-surface-water/maptiles/transitions/${z}/${x}/${y}.png",
        minZoom: 0, maxZoom: 19
    };

    // @see https://qms.nextgis.com/geoservices/1300/
    public static const ESRI_SATELLITE_ArcGIS:Object = {
        template: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
        minZoom: 0, maxZoom: 19
    };

    public function CommonCollection() {
    }
}
}


//http://online4.map.bdimg.com/tile/?qt=tile&styles=pl&x=-52984&y=-33004&z=19&scaler=2
//http://online2.map.bdimg.com/tile/?qt=tile&styles=sl&x=-50939&y=-31971&z=19&scaler=1
//http://online2.map.bdimg.com/tile/?qt=tile&styles=sl&x=-43900&y=-78998&z=17&scaler=1
//z=17&x=43900&y=78998&v=9"