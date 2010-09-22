//	MKAnnotationView.j
//	Evadne Wu at Iridia, 2010
	
	
	
	
	
@import <AppKit/CPView.j>

@import "MKGeometry.j"
@import "MKTypes.j"





@implementation MKAnnotationView : CPView {

	MKAnnotation annotation @accessors;
	CPString reuseIdentifier @accessors;
	
	BOOL enabled @accessors(getter=isEnabled);
	
}





- (MKAnnotationView) initWithAnnotation:(MKAnnotation)annotation reuseIdentifier:(CPString)reuseIdentifier {
	
	self = [super init]; if (self == nil) return nil;
	
	[self setAnnotation:annotation];
	[self setReuseIdentifier:reuseIdentifier];
	
	return self;
	
}





- (void) prepareForReuse {
	
	//	Empty
	
}





- (CGRect) visualBounds {
	
//	FIXME.
	return CGRectMakeZero();
	
}





@end




