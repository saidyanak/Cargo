package com.hilgo.cargo.response;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ResponseMeasure {

	private Long id;
	
	private Double weight;

	private Double height;	
}
