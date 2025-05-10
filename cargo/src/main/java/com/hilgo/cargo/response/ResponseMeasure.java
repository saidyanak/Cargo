package com.hilgo.cargo.response;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.Getter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ResponseMeasure {

	private Long id;
	
	private Double weight;

	private Double height;	
}
