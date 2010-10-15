//	MKAnnotationView.j
//	Looted from CappuGeo, Nicholas Small at 280 North

//	Evadne Wu at Iridia, 2010
	
@import <AppKit/CPView.j>
	
	
	
	
	
@implementation MKAnnotationView : CPView {
	
	MKAnnotation    annotation                  @accessors(readonly);
	CPImage         image                       @accessors;

	CGPoint         centerOffset                @accessors;
	CGPoint         calloutOffset               @accessors;

	BOOL            enabled                     @accessors(getter=isEnabled);
	BOOL            draggable                   @accessors(getter=isDraggable);
	BOOL            highlighted                 @accessors(getter=isHighlighted);
	BOOL            selected                    @accessors(readonly,getter=isSelected);

	BOOL            canShowCallout              @accessors;
	CPView          leftCalloutAccessoryView    @accessors;
	CPView          rightCalloutAccessoryView   @accessors;
	CPView          _calloutView;

	MKMapView       mapView                     @accessors;

}

- (id) initWithAnnotation:(MKAnnotation)anAnnotation {

	self = [super init]; if (self == nil) return nil;

	annotation = anAnnotation;

	centerOffset = CGPointMake(0.0, 0.0);
	calloutOffset = CGPointMake(0.0, 0.0);

	enabled = YES;
	draggable = NO;
	canShowCallout = NO;

	_listeners = [];

	return self;

}

@end